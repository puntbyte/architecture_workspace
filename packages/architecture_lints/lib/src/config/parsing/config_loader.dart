import 'dart:io';
import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/parsing/yaml_merger.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

class ConfigLoader {
  static final Map<String, _CachedEntry> _cache = {};

  static Future<ArchitectureConfig?> loadFromContext(String sourceFile) async {
    // 1. Find Root
    final root = findRootPath(sourceFile);
    if (root == null) return null;

    final configFilePath = p.join(root, ConfigKeys.configFilename);
    final configFile = File(configFilePath);

    if (!configFile.existsSync()) return null;

    final lastModified = configFile.lastModifiedSync();

    if (_cache.containsKey(configFilePath)) {
      final entry = _cache[configFilePath]!;
      if (entry.lastModified.isAtSameMomentAs(lastModified)) return entry.config;
    }

    try {
      final mergedMap = await YamlMerger.loadMergedYaml(configFilePath, projectRoot: root);

      final config = ArchitectureConfig.fromYaml(mergedMap);

      _cache[configFilePath] = _CachedEntry(config, lastModified);
      return config;
    } catch (e) {
      return null;
    }
  }

  /// Exposed helper to find the directory containing architecture.yaml
  static String? findRootPath(String filePath) {
    final normalizedPath = filePath.replaceAll(r'\', '/');
    return _findProjectRoot(normalizedPath);
  }

  static String? _findProjectRoot(String path) {
    var directory = Directory(p.dirname(path));
    for (var i = 0; i < 20; i++) {
      final configPath = p.join(directory.path, ConfigKeys.configFilename);
      if (File(configPath).existsSync()) return directory.path;
      if (directory.parent.path == directory.path) break;
      directory = directory.parent;
    }

    return null;
  }

  @visibleForTesting
  static void resetCache() => _cache.clear();
}

class _CachedEntry {
  final ArchitectureConfig config;
  final DateTime lastModified;

  _CachedEntry(this.config, this.lastModified);
}
