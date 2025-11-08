// lib/src/utils/path_utils.dart
import 'dart:io';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:clean_architecture_kit/src/utils/string_extension.dart';
import 'package:path/path.dart' as p;

/// A utility class providing static methods for path resolution.
class PathUtils {
  const PathUtils._();

  /// Finds the project root directory by searching upwards for a `pubspec.yaml` file.
  static String? findProjectRoot(String fileAbsolutePath) {
    var dir = Directory(p.dirname(fileAbsolutePath));
    while (true) {
      if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir.path;
      if (p.equals(dir.parent.path, dir.path)) return null;
      dir = dir.parent;
    }
  }

  /// Determines the absolute path of the `usecases` directory for a given repository file.
  static String? getUseCasesDirectoryPath(String repoPath, CleanArchitectureConfig config) {
    final projectRoot = findProjectRoot(repoPath);
    if (projectRoot == null) return null;

    final normalized = p.normalize(repoPath).replaceAll(r'\', '/');
    final segments = normalized.split('/');
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;

    final insideLibSegments = segments.sublist(libIndex + 1);
    final layerCfg = config.layers;
    final useCaseDir = layerCfg.domainUseCasesPaths.firstOrNull ?? 'usecases';

    if (layerCfg.projectStructure == 'feature_first') {
      if (insideLibSegments.length < 3 || insideLibSegments.first != layerCfg.featuresRootPath) {
        return null;
      }
      final featureName = insideLibSegments[1];
      return p.join(
        projectRoot,
        'lib',
        layerCfg.featuresRootPath,
        featureName,
        'domain',
        useCaseDir,
      );
    } else {
      // layer_first
      return p.join(projectRoot, 'lib', layerCfg.domainPath, useCaseDir);
    }
  }

  /// Determines the full, absolute path for a new use case file.
  static String? getUseCaseFilePath({
    required String methodName,
    required String repoPath,
    required CleanArchitectureConfig config,
  }) {
    final useCaseDir = getUseCasesDirectoryPath(repoPath, config);
    if (useCaseDir == null) return null;

    final useCaseClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);
    final useCaseFileName = '${useCaseClassName.toSnakeCase()}.dart';
    return p.join(useCaseDir, useCaseFileName);
  }

  /// Checks if a given path is inside any configured entity directory.
  static bool isPathInEntityDirectory(
    String path,
    CleanArchitectureConfig config,
    LayerResolver resolver,
  ) {
    // The most robust way is to delegate to the LayerResolver.
    return resolver.getSubLayer(path) == ArchSubLayer.entity;
  }
}
