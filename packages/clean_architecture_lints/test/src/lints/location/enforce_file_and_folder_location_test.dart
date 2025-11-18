// test/src/lints/location/enforce_file_and_folder_location_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/location/enforce_file_and_folder_location.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceFileAndFolderLocation Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;
    late String testProjectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint({required String filePath}) async {
      final config = makeConfig(); // Uses a full set of default naming rules
      final lint = EnforceFileAndFolderLocation(
        config: config,
        layerResolver: LayerResolver(config),
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
      tempDir = Directory.systemTemp.createTempSync('file_location_test_');
      projectPath = p.normalize(tempDir.path);
      testProjectPath = p.join(projectPath, 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when a Model is found in an entities directory', () async {
      // Path is for an entity, but the class name matches the model pattern.
      final path = p.join(testProjectPath, 'lib/features/user/domain/entities/user_model.dart');
      writeFile(path, 'class UserModel {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_file_and_folder_location');
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'A Model was found in a "Entity" directory, but it belongs in a "Model" directory.',
      );
    });

    test('should report violation when an Entity is found in a models directory', () async {
      // Path is for a model, but the class name matches the entity pattern.
      final path = p.join(testProjectPath, 'lib/features/user/data/models/user.dart');
      writeFile(path, 'class User {}'); // `{{name}}` pattern matches Entity/UseCase

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'A Entity was found in a "Model" directory, but it belongs in a "Entity" directory.',
      );
    });

    test('should not report violation when a Model is in a models directory', () async {
      final path = p.join(testProjectPath, 'lib/features/user/data/models/user_model.dart');
      writeFile(path, 'class UserModel {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('should not report violation when an Entity is in an entities directory', () async {
      final path = p.join(testProjectPath, 'lib/features/user/domain/entities/user.dart');
      writeFile(path, 'class User {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('should not report violation when file is in an unknown location', () async {
      // The `core` directory is not an architectural layer.
      final path = p.join(testProjectPath, 'lib/core/models/some_model.dart');
      writeFile(path, 'class SomeModel {}');

      final lints = await runLint(filePath: path);
      expect(
        lints,
        isEmpty,
        reason: 'Lint should not run on files in non-architectural directories.',
      );
    });
  });
}
