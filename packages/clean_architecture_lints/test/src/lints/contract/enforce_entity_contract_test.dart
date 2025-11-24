// test/src/lints/contract/enforce_entity_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_entity_contract.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceEntityContract Lint', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('entity_contract_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Create a local definition of Entity
      addFile('lib/core/entity/entity.dart', 'abstract class Entity {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(inheritances: inheritances);
      final lint = EnforceEntityContract(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when entity does not extend Entity', () async {
      final path = 'lib/features/login/domain/entities/user.dart';
      addFile(path, 'class User {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Entities must extend or implement: Entity'));
    });

    test('does not report violation when entity extends Entity (Local Core)', () async {
      final path = 'lib/features/login/domain/entities/user.dart';
      addFile(path, '''
        import 'package:test_project/core/entity/entity.dart';
        class User extends Entity {} 
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('ignores abstract entity classes', () async {
      final path = 'lib/features/shared/domain/entities/base_user.dart';
      addFile(path, 'abstract class BaseUser {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('ignores files outside of the entity directory', () async {
      final path = 'lib/features/login/presentation/pages/login_page.dart';
      addFile(path, 'class LoginPage {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('DISABLES itself when a custom inheritance rule for Entity is defined', () async {
      final customConfig = [
        {
          'on': 'entity',
          'required': {'name': 'CustomBase', 'import': 'pkg:x'}
        }
      ];

      final path = 'lib/features/login/domain/entities/user.dart';
      addFile(path, 'class User {}');

      final lints = await runLint(
        filePath: path,
        inheritances: customConfig,
      );

      expect(lints, isEmpty, reason: 'Lint should be disabled when custom rule exists');
    });
  });
}