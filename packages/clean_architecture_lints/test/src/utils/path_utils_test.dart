// test/src/utils/path_utils_test.dart

import 'dart:io';

import 'package:clean_architecture_lints/src/utils/path_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('PathUtils', () {
    late Directory tempDir;
    late String projectRoot;

    // Create a fresh temporary project directory before each test.
    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('path_utils_test_');
      projectRoot = tempDir.path;
      // The presence of pubspec.yaml defines the project root.
      await File(p.join(projectRoot, 'pubspec.yaml')).writeAsString('name: test_project');
    });

    // Clean up the temporary directory after each test.
    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('findProjectRoot', () {
      test('should find the project root from a deeply nested file path', () async {
        final nestedFile = await File(
          p.join(projectRoot, 'lib', 'deep', 'core', 'utils', 'file.dart'),
        ).create(recursive: true);

        final foundRoot = PathUtils.findProjectRoot(nestedFile.path);

        expect(foundRoot, isNotNull);
        // Normalize paths to handle OS-specific separators (e.g., \ vs /).
        expect(p.normalize(foundRoot!), p.normalize(projectRoot));
      });

      test('should return null when not inside a project (no pubspec.yaml)', () {
        // This path is outside our created project root.
        final outsidePath = Directory.systemTemp.path;
        final foundRoot = PathUtils.findProjectRoot(p.join(outsidePath, 'file.dart'));
        expect(foundRoot, isNull);
      });
    });

    group('getUseCasesDirectoryPath', () {
      group('when in a feature-first project', () {
        test('should return the correct feature-specific usecase path', () async {
          final repoFile = await File(
            p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'contracts', 'repo.dart'),
          ).create(recursive: true);
          final config = makeConfig(projectStructure: 'feature_first');

          final result = PathUtils.getUseCasesDirectoryPath(repoFile.path, config);
          final expected = p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'usecases');

          expect(p.normalize(result!), p.normalize(expected));
        });
      });

      group('when in a layer-first project', () {
        test('should return the correct global domain usecase path', () async {
          final repoFile = await File(
            p.join(projectRoot, 'lib', 'domain', 'contracts', 'repo.dart'),
          ).create(recursive: true);
          final config = makeConfig(projectStructure: 'layer_first');

          final result = PathUtils.getUseCasesDirectoryPath(repoFile.path, config);
          final expected = p.join(projectRoot, 'lib', 'domain', 'usecases');

          expect(p.normalize(result!), p.normalize(expected));
        });
      });

      test('should return null when the repository path is not inside the lib directory', () async {
        // Create a file outside 'lib'
        final repoFile = await File(
          p.join(projectRoot, 'test', 'some_repo.dart'),
        ).create(recursive: true);
        final config = makeConfig();

        final result = PathUtils.getUseCasesDirectoryPath(repoFile.path, config);
        expect(result, isNull);
      });
    });

    group('getUseCaseFilePath', () {
      test('should construct the full file path for a new use case', () async {
        final repoFile = await File(
          p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'contracts', 'repo.dart'),
        ).create(recursive: true);
        // Configure a custom suffix to ensure the NamingUtils is being used correctly.
        final config = makeConfig(useCaseNaming: '{{name}}Action');

        final resultPath = PathUtils.getUseCaseFilePath(
          methodName: 'getUser',
          repoPath: repoFile.path,
          config: config,
        );

        expect(resultPath, isNotNull);

        final expectedDir = p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'usecases');
        const expectedFile = 'get_user_action.dart';

        // Check that the directory and filename are both correct.
        expect(p.dirname(resultPath!), p.normalize(expectedDir));
        expect(p.basename(resultPath), expectedFile);
      });
    });
  });
}
