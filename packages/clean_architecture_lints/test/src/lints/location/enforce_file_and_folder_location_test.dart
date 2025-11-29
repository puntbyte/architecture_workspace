// test/src/lints/location/enforce_file_and_folder_location_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/location/enforce_file_and_folder_location.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceFileAndFolderLocation Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('file_location_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: example');
      // Package config setup (good practice, though relative imports bypass the need for it)
      final libUri = p.toUri(p.join(testProjectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [
          {"name": "example", "rootUri": "$libUri", "packageUri": "."}
        ]
      }
      ''');

      // Define base class for inheritance test
      addFile('lib/core/port.dart', 'abstract class Port {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? inheritances,
      List<Map<String, dynamic>>? namingRules,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      // Default config usually has Entity={{name}} and Model={{name}}Model
      // We override if params are provided
      final config = makeConfig(
        inheritances: inheritances,
        namingRules: namingRules,
      );

      final lint = EnforceFileAndFolderLocation(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when a Model is found in an entities directory', () async {
      const path = 'lib/features/user/domain/entities/user_model.dart';
      addFile(path, 'class UserModel {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('A Model was found in a "Entity" directory'));
    });

    test('reports violation when an Entity is found in a models directory', () async {
      const path = 'lib/features/user/data/models/user.dart';
      addFile(path, 'class User {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('A Entity was found in a "Model" directory'));
    });

    test(
      'should NOT report violation if class implements the correct contract for its location',
      () async {
        // Scenario: 'AuthContract' matches Entity name pattern ({{name}}), but is in Port folder.
        // It implements Port, so location lint should accept it.

        final inheritances = [
          {
            'on': 'port',
            'required': {'name': 'Port', 'import': 'package:example/core/port.dart'},
          },
        ];

        final namingRules = [
          {'on': 'entity', 'pattern': '{{name}}'},
          {'on': 'port', 'pattern': '{{name}}Port'},
        ];

        const path = 'lib/features/auth/domain/ports/auth_contract.dart';

        // FIX: Use relative import to ensure the analyzer resolves 'Port' correctly.
        addFile(path, '''
        import '../../../../core/port.dart';
        abstract interface class AuthContract implements Port {} 
        ''');

        final lints = await runLint(
          filePath: path,
          inheritances: inheritances,
          namingRules: namingRules,
        );

        expect(lints, isEmpty, reason: 'Inheritance check should override name-based guess');
      },
    );

    test('handles pattern collisions gracefully', () async {
      // Login matches both Entity ({{name}}) and UseCase ({{name}}).
      // It is in UseCases folder. Should pass.
      const path = 'lib/features/auth/domain/usecases/login.dart';
      addFile(path, 'class Login {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}
