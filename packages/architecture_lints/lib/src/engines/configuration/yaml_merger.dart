// lib/src/engines/configuration/yaml_merger.dart

import 'dart:io';
import 'package:architecture_lints/src/engines/configuration/package_path_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class YamlMerger {
  const YamlMerger._();

  /// Loads merged YAML.
  /// [projectRoot] is required to resolve 'package:' includes.
  static Future<Map<dynamic, dynamic>> loadMergedYaml(
    String filePath, {
    Set<String>? seenPaths,
    String? projectRoot,
  }) async {
    final normalizedPath = p.normalize(p.absolute(filePath));

    final visited = seenPaths ?? {};
    if (visited.contains(normalizedPath)) {
      throw FormatException('Circular dependency detected in #include: $normalizedPath');
    }
    visited.add(normalizedPath);

    final file = File(normalizedPath);
    if (!file.existsSync()) return {};

    final content = await file.readAsString();

    // 1. Process #include
    final includeRegex = RegExp(r'^\s*#\s*include:\s*(.+)$', multiLine: true);
    final match = includeRegex.firstMatch(content);

    var baseConfig = <dynamic, dynamic>{};

    if (match != null) {
      final includePath = match.group(1)?.trim();
      if (includePath != null && includePath.isNotEmpty) {
        String? absoluteIncludePath;

        // CASE A: Package Import
        if (includePath.startsWith('package:')) {
          if (projectRoot != null) {
            absoluteIncludePath = await PackagePathResolver.resolve(
              packageUri: includePath,
              projectRoot: projectRoot,
            );
          }
        }
        // CASE B: Relative Import
        else {
          final currentDir = p.dirname(normalizedPath);
          absoluteIncludePath = p.join(currentDir, includePath);
        }

        if (absoluteIncludePath != null) {
          baseConfig = await loadMergedYaml(
            absoluteIncludePath,
            seenPaths: visited,
            projectRoot: projectRoot, // Propagate root
          );
        }
      }
    }

    // 2. Parse & Merge
    final currentYaml = loadYaml(content);
    var currentMap = <dynamic, dynamic>{};
    if (currentYaml is Map) currentMap = currentYaml;

    return _deepMerge(baseConfig, currentMap);
  }

  static Map<dynamic, dynamic> _deepMerge(
    Map<dynamic, dynamic> base,
    Map<dynamic, dynamic> override,
  ) {
    final result = Map<dynamic, dynamic>.from(base);

    override.forEach((key, value) {
      final baseValue = result[key];

      if (baseValue is Map && value is Map) {
        result[key] = _deepMerge(baseValue, value);
      } else if (baseValue is List && value is List) {
        // Appending lists allows mixing standards + project specifics
        result[key] = [...baseValue, ...value];
      } else {
        result[key] = value;
      }
    });

    return result;
  }
}
