// test/lints/contract/enforce_entity_contract_test.dart

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
      tempDir = Directory.systemTemp.createTempSync('clean_arch_lint_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );

      addFile('lib/core/entity/entity.dart', 'abstract class Entity {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore cleanup errors on Windows (file locks)
      }
    });

    Future<List<Diagnostic>> runLint(
      String filePath, {
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(inheritances: inheritances);
      final rule = EnforceEntityContract(config: config, layerResolver: LayerResolver(config));

      final lints = await rule.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports error when entity does not extend default Base Entity', () async {
      addFile('lib/features/login/domain/entities/user.dart', '''
        class User {} 
      ''');
      final lints = await runLint('lib/features/login/domain/entities/user.dart');
      expect(lints, hasLength(1));
      expect(lints.first.message, 'Entities must extend or implement: Entity.');
    });

    test('reports no error when entity extends default Base Entity (Local)', () async {
      addFile('lib/features/login/domain/entities/user.dart', '''
        import 'package:test_project/core/entity/entity.dart';
        class User extends Entity {} 
      ''');
      final lints = await runLint('lib/features/login/domain/entities/user.dart');
      expect(lints, isEmpty);
    });

    test('supports custom inheritance configuration', () async {
      addFile('lib/domain/base/custom_entity.dart', 'abstract class CustomEntity {}');
      addFile('lib/features/login/domain/entities/user.dart', '''
        import 'package:test_project/domain/base/custom_entity.dart';
        class User extends CustomEntity {} 
      ''');

      final customConfig = [
        {
          'on': 'entity',
          'required': {
            'name': 'CustomEntity',
            'import': 'package:test_project/domain/base/custom_entity.dart',
          },
        },
      ];

      final lints = await runLint(
        'lib/features/login/domain/entities/user.dart',
        inheritances: customConfig,
      );
      expect(lints, isEmpty);
    });

    test('reports error if using default entity when custom config is present', () async {
      addFile('lib/features/login/domain/entities/user.dart', '''
        import 'package:test_project/core/entity/entity.dart';
        class User extends Entity {} 
      ''');

      final customConfig = [
        {
          'on': 'entity',
          'required': {'name': 'CustomEntity', 'import': 'pkg:x'},
        },
      ];

      final lints = await runLint(
        'lib/features/login/domain/entities/user.dart',
        inheritances: customConfig,
      );
      expect(lints, hasLength(1));
      expect(lints.first.message, contains('CustomEntity'));
    });
  });
}
