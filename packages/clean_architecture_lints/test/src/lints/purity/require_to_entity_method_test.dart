import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/purity/require_to_entity_method.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('RequireToEntityMethod Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint(String filePath) async {
      final config = makeConfig();
      final lint = RequireToEntityMethod(config: config, layerResolver: LayerResolver(config));

      final resolvedUnit = await contextCollection
          .contextFor(p.normalize(filePath))
          .currentSession
          .getResolvedUnit(p.normalize(filePath)) as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('require_to_entity_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(p.join(testProjectPath, '.dart_tool/package_config.json'),
          '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}');

      // Define the Entity that the Model should map to.
      writeFile(
        p.join(testProjectPath, 'lib/features/user/domain/entities/user.dart'),
        'class User {}',
      );
      // Define another unrelated entity for a negative test case.
      writeFile(
        p.join(testProjectPath, 'lib/features/product/domain/entities/product.dart'),
        'class Product {}',
      );

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when toEntity method is missing', () async {
      final path = p.join(testProjectPath, 'lib/features/user/data/models/user_model.dart');
      writeFile(path, '''
        import 'package:test_project/features/user/domain/entities/user.dart';
        class UserModel extends User {}
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'require_to_entity_method');
      expect(lints.first.problemMessage.messageText(includeUrl: false),
          'The model `UserModel` must have a `toEntity()` method that returns its corresponding Entity.');
    });

    test('should report violation when toEntity method has the wrong return type', () async {
      final path = p.join(testProjectPath, 'lib/features/user/data/models/user_model.dart');
      writeFile(path, '''
        import 'package:test_project/features/user/domain/entities/user.dart';
        import 'package:test_project/features/product/domain/entities/product.dart';
        
        class UserModel extends User {
          Product toEntity() => Product(); // VIOLATION: Should return User
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('should not report violation for a correctly implemented toEntity method', () async {
      final path = p.join(testProjectPath, 'lib/features/user/data/models/user_model.dart');
      writeFile(path, '''
        import 'package:test_project/features/user/domain/entities/user.dart';
        
        class UserModel extends User {
          User toEntity() => User();
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should not report violation for a model that does not extend an entity', () async {
      final path = p.join(testProjectPath, 'lib/features/user/data/models/auth_response_model.dart');
      writeFile(path, 'class AuthResponseModel {}'); // Does not extend an Entity

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should not run on files that are not models', () async {
      final path = p.join(testProjectPath, 'lib/features/user/domain/entities/user.dart');
      // The content is a model, but the location is wrong. The lint should ignore it.
      writeFile(path, 'class UserModel { User toEntity() => User(); }');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}
