// lib/src/utils/path_utils.dart

import 'dart:io';

import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/models/module_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:path/path.dart' as p;

/// A utility class providing static methods for file system path resolution.
class PathUtils {
  const PathUtils._();

  /// Walks up to find `pubspec.yaml`.
  static String? findProjectRoot(String fileAbsolutePath) {
    // Guard against non-file paths
    if (fileAbsolutePath.isEmpty) return null;

    try {
      var dir = Directory(p.dirname(fileAbsolutePath));
      // Safety max depth to prevent infinite loops in weird file systems
      var depth = 0;
      const maxDepth = 50;

      while (depth < maxDepth) {
        if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
          return dir.path;
        }
        final parent = dir.parent;
        if (p.equals(parent.path, dir.path)) return null; // Reached root
        dir = parent;
        depth++;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static String? getUseCasesDirectoryPath(String repoPath, ArchitectureConfig config) {
    final projectRoot = findProjectRoot(repoPath);
    final segments = _getRelativePathSegments(repoPath);

    if (projectRoot == null || segments == null) return null;

    final modules = config.modules;
    final layers = config.layers;
    // Fallback to 'usecases' if config is empty
    final useCaseDirName = layers.domain.usecase.firstOrNull ?? 'usecases';

    if (modules.type == ModuleType.featureFirst &&
        segments.length >= 2 &&
        segments.first == modules.features) {
      final featureName = segments[1];
      return p.join(
        projectRoot,
        'lib',
        modules.features,
        featureName,
        modules.domain,
        useCaseDirName,
      );
    }

    if (modules.type == ModuleType.layerFirst) {
      return p.join(projectRoot, 'lib', modules.domain, useCaseDirName);
    }

    return null;
  }

  /// Constructs the full, absolute file path for an expected use case file.
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

  static List<String>? _getRelativePathSegments(String absolutePath) {
    final normalized = p.normalize(absolutePath);
    final segments = p.split(normalized);
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;
    return segments.sublist(libIndex + 1);
  }
}
