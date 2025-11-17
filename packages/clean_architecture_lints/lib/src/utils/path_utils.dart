// lib/src/utils/path_utils.dart

import 'dart:io';

import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:path/path.dart' as p;

/// A utility class providing static methods for file system path resolution.
class PathUtils {
  const PathUtils._();

  static String? findProjectRoot(String fileAbsolutePath) {
    var dir = Directory(p.dirname(fileAbsolutePath));
    while (true) {
      if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir.path;
      if (p.equals(dir.parent.path, dir.path)) return null;
      dir = dir.parent;
    }
  }

  static String? getUseCasesDirectoryPath(String repoPath, ArchitectureConfig config) {
    final projectRoot = findProjectRoot(repoPath);
    if (projectRoot == null) return null;

    final normalized = p.normalize(repoPath).replaceAll(r'\', '/');
    final segments = normalized.split('/');
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;

    final insideLibSegments = segments.sublist(libIndex + 1);
    final layerCfg = config.layers;
    final useCaseDir = layerCfg.domain.usecase.firstOrNull ?? 'usecases';

    if (insideLibSegments.length >= 3 && insideLibSegments.first == layerCfg.featuresModule) {
      final featureName = insideLibSegments[1];
      return p.join(projectRoot, 'lib', layerCfg.featuresModule, featureName, 'domain', useCaseDir);
    }

    return p.join(projectRoot, 'lib', 'domain', useCaseDir);
  }

  static String? getUseCaseFilePath({
    required String methodName,
    required String repoPath,
    required ArchitectureConfig config,
  }) {
    final useCaseDir = getUseCasesDirectoryPath(repoPath, config);
    if (useCaseDir == null) return null;

    final useCaseClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);
    final useCaseFileName = '${useCaseClassName.toSnakeCase()}.dart';
    return p.join(useCaseDir, useCaseFileName);
  }
}
