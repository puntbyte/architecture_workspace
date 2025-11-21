// test/srcs/lints/naming/enforce_semantic_naming_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/naming/enforce_semantic_naming.dart';
import 'package:clean_architecture_lints/src/utils/natural_language_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceSemanticNaming Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;
    late NaturalLanguageUtils nlpUtils;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> namingRules,
    }) async {
      final config = makeConfig(namingRules: namingRules);
      final lint = EnforceSemanticNaming(
        config: config,
        layerResolver: LayerResolver(config),
        nlpUtils: nlpUtils,
      );

      final resolvedUnit =
          await contextCollection
                  .contextFor(p.normalize(filePath))
                  .currentSession
                  .getResolvedUnit(p.normalize(filePath))
              as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('semantic_naming_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      // Create a deterministic NLP utility for tests.
      nlpUtils = NaturalLanguageUtils(
        posOverrides: {
          'get': {'VERB'},
          'fetch': {'VERB'},
          'user': {'NOUN'},
          'profile': {'NOUN'},
          'loading': {'NOUN', 'ADJ'},
          'loaded': {'VERB', 'ADJ'},
          'initial': {'ADJ'},
        },
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('Usecase Grammar: {{verb.present}}{{noun.phrase}}', () {
      final usecaseRule = {'on': 'usecase', 'grammar': '{{verb.present}}{{noun.phrase}}'};

      test('should not report violation for a valid Verb+Noun name', () async {
        final path = p.join(testProjectPath, 'lib/features/user/domain/usecases/get_user.dart');
        writeFile(path, 'class GetUser {}');
        final lints = await runLint(filePath: path, namingRules: [usecaseRule]);
        expect(lints, isEmpty);
      });

      test('should report violation for a Noun+Verb name', () async {
        final path = p.join(testProjectPath, 'lib/features/user/domain/usecases/user_get.dart');
        writeFile(path, 'class UserGet {}');
        final lints = await runLint(filePath: path, namingRules: [usecaseRule]);
        expect(lints, hasLength(1));
      });
    });

    group('Model Grammar: {{noun.phrase}}Model', () {
      final modelRule = {'on': 'model', 'grammar': '{{noun.phrase}}Model'};

      test('should not report violation for a valid Noun+Suffix name', () async {
        final path = p.join(
          testProjectPath,
          'lib/features/user/data/models/user_profile_model.dart',
        );
        writeFile(path, 'class UserProfileModel {}');
        final lints = await runLint(filePath: path, namingRules: [modelRule]);
        expect(lints, isEmpty);
      });

      test('should report violation when phrase before suffix is not a noun', () async {
        final path = p.join(testProjectPath, 'lib/features/user/data/models/fetch_user_model.dart');
        writeFile(path, 'class FetchUserModel {}');
        final lints = await runLint(filePath: path, namingRules: [modelRule]);
        expect(lints, hasLength(1));
      });
    });

    group('State Grammar: {{subject}}({{adjective}}|{{verb.gerund}}|{{verb.past}})', () {
      final stateRule = {
        'on': 'state.implementation',
        'grammar': '{{subject}}({{adjective}}|{{verb.gerund}}|{{verb.past}})',
      };

      test('should not report violation for a valid State name (Adjective)', () async {
        final path = p.join(
          testProjectPath,
          'lib/features/auth/presentation/managers/auth_state.dart',
        );
        writeFile(path, 'class AuthInitial {}'); // `Initial` is an adjective
        final lints = await runLint(filePath: path, namingRules: [stateRule]);
        expect(lints, isEmpty);
      });

      test('should not report violation for a valid State name (Gerund)', () async {
        final path = p.join(
          testProjectPath,
          'lib/features/auth/presentation/managers/auth_state.dart',
        );
        writeFile(
          path,
          'class AuthLoading {}',
        ); // `Loading` is a gerund (and a noun, which is fine)
        final lints = await runLint(filePath: path, namingRules: [stateRule]);
        expect(lints, isEmpty);
      });
    });

    test('should be silent when a rule has no grammar property', () async {
      final path = p.join(testProjectPath, 'lib/features/user/domain/usecases/get_user.dart');
      writeFile(path, 'class GetUser {}');

      // Rule has a pattern but no grammar.
      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'usecase', 'pattern': '{{name}}'},
        ],
      );

      expect(lints, isEmpty);
    });
  });
}
