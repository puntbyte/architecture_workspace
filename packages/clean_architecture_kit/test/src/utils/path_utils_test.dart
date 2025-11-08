// test/src/utils/path_utils_test.dart

import 'dart:io';

import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/path_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// A single, powerful test helper for creating config.
CleanArchitectureConfig makeTestConfig({
  String projectStructure = 'feature_first',
  String featuresRoot = 'features',
  String domainPath = 'domain',
  List<String> useCasesPaths = const ['usecases'],
  List<String> entitiesPaths = const ['entities'],
  String useCaseNaming = '{{name}}',
}) {
  return CleanArchitectureConfig.fromMap({
    'project_structure': projectStructure,
    'feature_first_paths': {'features_root': featuresRoot},
    'layer_first_paths': {'domain': domainPath},
    'layer_definitions': {
      'domain': {'usecases': useCasesPaths, 'entities': entitiesPaths},
    },
    'naming_conventions': {'use_case': useCaseNaming},
    'type_safety': {}, 'inheritance': {}, 'generation_options': {}, 'service_locator': {},
  });
}

void main() {
  late Directory tempProjectDir;
  late String projectRoot;

  // This setup creates a temporary file system structure for each test group.
  Future<void> createTempProject() async {
    tempProjectDir = await Directory.systemTemp.createTemp('path_utils_test_');
    projectRoot = tempProjectDir.path;
    await File(p.join(projectRoot, 'pubspec.yaml')).writeAsString('name: test_project');
  }

  tearDownAll(() async {
    if (await tempProjectDir.exists()) {
      await tempProjectDir.delete(recursive: true);
    }
  });

  group('findProjectRoot', () {
    setUp(createTempProject);

    test('should find the project root from a nested file path', () async {
      final nestedDir = await Directory(p.join(projectRoot, 'lib', 'deep', 'folder')).create(recursive: true);
      final nestedFile = File(p.join(nestedDir.path, 'file.dart'));
      final foundRoot = PathUtils.findProjectRoot(nestedFile.path);
      expect(p.normalize(foundRoot!), p.normalize(projectRoot));
    });
  });

  group('getUseCasesDirectoryPath', () {
    group('in feature-first structure', () {
      setUp(createTempProject);

      test('should return the correct usecase path for a feature', () async {
        final repoFile = await File(p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'contracts', 'repo.dart'))
            .create(recursive: true);
        final config = makeTestConfig();
        final result = PathUtils.getUseCasesDirectoryPath(repoFile.path, config);
        final expected = p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'usecases');
        expect(p.normalize(result!), p.normalize(expected));
      });
    });

    group('in layer-first structure', () {
      setUp(createTempProject);

      test('should return the correct usecase path', () async {
        final repoFile = await File(p.join(projectRoot, 'lib', 'domain', 'contracts', 'repo.dart'))
            .create(recursive: true);
        final config = makeTestConfig(projectStructure: 'layer_first');
        final result = PathUtils.getUseCasesDirectoryPath(repoFile.path, config);
        final expected = p.join(projectRoot, 'lib', 'domain', 'usecases');
        expect(p.normalize(result!), p.normalize(expected));
      });
    });
  });

  group('getUseCaseFilePath', () {
    setUp(createTempProject);

    test('should construct the full file path for a new use case', () async {
      final repoFile = await File(p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'contracts', 'repo.dart'))
          .create(recursive: true);
      final config = makeTestConfig(useCaseNaming: '{{name}}UseCase');
      final result = PathUtils.getUseCaseFilePath(
        methodName: 'getUser',
        repoPath: repoFile.path,
        config: config,
      );
      final expected = p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'usecases', 'get_user_use_case.dart');
      expect(p.normalize(result!), p.normalize(expected));
    });
  });

  group('isPathInEntityDirectory', () {
    setUp(createTempProject);

    test('should return true for a file inside a configured entity directory', () async {
      final entityFile = await File(p.join(projectRoot, 'lib', 'features', 'user', 'domain', 'entities', 'user.dart'))
          .create(recursive: true);
      final config = makeTestConfig();
      final resolver = LayerResolver(config);
      expect(PathUtils.isPathInEntityDirectory(entityFile.path, config, resolver), isTrue);
    });

    test('should return false for a file outside an entity directory', () async {
      final modelFile = await File(p.join(projectRoot, 'lib', 'features', 'user', 'data', 'models', 'user_model.dart'))
          .create(recursive: true);
      final config = makeTestConfig();
      final resolver = LayerResolver(config);
      expect(PathUtils.isPathInEntityDirectory(modelFile.path, config, resolver), isFalse);
    });
  });
}
