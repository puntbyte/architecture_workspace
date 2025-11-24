// test/src/lints/naming/enforce_semantic_naming_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/naming/enforce_semantic_naming.dart';
import 'package:clean_architecture_lints/src/utils/nlp/natural_language_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceSemanticNaming Lint', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;
    late NaturalLanguageUtils nlpUtils;

    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('semantic_naming_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Mock Dictionary for consistent results
      nlpUtils = NaturalLanguageUtils(
        posOverrides: {
          'get': {'VERB'},
          'fetch': {'VERB'},
          'fetching': {'VERB'}, // Gerunds usually derived, but explicit override helps test stability
          'user': {'NOUN'},
          'profile': {'NOUN'},
          'loading': {'NOUN', 'ADJ'},
          'loaded': {'VERB', 'ADJ'},
          'initial': {'ADJ'},
        },
      );
    });

    tearDown(() {
      try { tempDir.deleteSync(recursive: true); } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> namingRules,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(namingRules: namingRules);
      final lint = EnforceSemanticNaming(
        config: config,
        layerResolver: LayerResolver(config),
        nlpUtils: nlpUtils,
      );

      return lint.testRun(resolvedUnit);
    }

    group('Entity Grammar: {{noun.phrase}}', () {
      final entityRule = {'on': 'entity', 'grammar': '{{noun.phrase}}'};

      test('reports violation for "FetchingUser" (Gerund/Verb start)', () async {
        final path = 'lib/features/user/domain/entities/fetching_user.dart';
        addFile(path, 'class FetchingUser {}');

        final lints = await runLint(filePath: path, namingRules: [entityRule]);

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('does not follow the grammatical structure'));
      });

      test('reports violation for "GetUser" (Verb start)', () async {
        final path = 'lib/features/user/domain/entities/get_user.dart';
        addFile(path, 'class GetUser {}');

        final lints = await runLint(filePath: path, namingRules: [entityRule]);
        expect(lints, hasLength(1));
      });

      test('reports violation for "UserFetch" (Verb end)', () async {
        final path = 'lib/features/user/domain/entities/user_fetch.dart';
        addFile(path, 'class UserFetch {}'); // Ends with verb, not noun

        final lints = await runLint(filePath: path, namingRules: [entityRule]);
        expect(lints, hasLength(1));
      });

      test('validates "UserProfile" (Noun Phrase)', () async {
        final path = 'lib/features/user/domain/entities/user_profile.dart';
        addFile(path, 'class UserProfile {}');

        final lints = await runLint(filePath: path, namingRules: [entityRule]);
        expect(lints, isEmpty);
      });
    });

    group('Usecase Grammar: {{verb.present}}{{noun.phrase}}', () {
      final usecaseRule = {'on': 'usecase', 'grammar': '{{verb.present}}{{noun.phrase}}'};

      test('validates "GetUser" (Verb+Noun)', () async {
        final path = 'lib/features/user/domain/usecases/get_user.dart';
        addFile(path, 'class GetUser {}');
        final lints = await runLint(filePath: path, namingRules: [usecaseRule]);
        expect(lints, isEmpty);
      });

      test('reports violation for "UserGet" (Noun+Verb)', () async {
        final path = 'lib/features/user/domain/usecases/user_get.dart';
        addFile(path, 'class UserGet {}');
        final lints = await runLint(filePath: path, namingRules: [usecaseRule]);
        expect(lints, hasLength(1));
      });
    });
  });
}