import 'dart:io';
import 'package:architecture_lints/src/configuration/component_config.dart';
import 'package:architecture_lints/src/configuration/config_keys.dart';
import 'package:architecture_lints/src/configuration/project_config.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class ConfigLoader {
  static ProjectConfig? _cachedConfig;

  static ProjectConfig? getCachedConfig() => _cachedConfig;

  static Future<ProjectConfig?> load(String rootPath) async {
    if (_cachedConfig != null) return _cachedConfig;

    final file = File(p.join(rootPath, 'architecture.yaml'));

    if (!file.existsSync()) {
      final altFile = File(p.join(rootPath, 'architecture.yml'));
      if (!altFile.existsSync()) return null;
    }

    final content = await file.readAsString();

    try {
      final yaml = loadYaml(content);
      if (yaml is! YamlMap) return null;

      return _cachedConfig = parseYaml(yaml);
    } catch (e, stack) {
      print('Architecture Lints: Error parsing YAML: $e\n$stack');
      return null;
    }
  }

  @visibleForTesting
  static ProjectConfig parseYaml(YamlMap yaml) {
    final components = <String, ComponentConfig>{};

    if (yaml.containsKey(ConfigKeys.root.components)) {
      final compMap = yaml[ConfigKeys.root.components] as YamlMap;

      for (final key in compMap.keys) {
        final id = key.toString();
        final node = compMap[key];
        final config = _parseComponent(id, node);
        if (config != null) {
          components[id] = config;
        }
      }
    }

    return ProjectConfig(components: components);
  }

  static ComponentConfig? _parseComponent(String id, dynamic node) {
    if (node is! YamlMap) return null;

    var path = node[ConfigKeys.component.path]?.toString();
    if (path != null) path = p.normalize(path);

    return ComponentConfig(
      id: id,
      name: node[ConfigKeys.component.name]?.toString() ?? id,
      path: path,
      pattern: node[ConfigKeys.component.pattern]?.toString(),
      antipattern: node[ConfigKeys.component.antipattern]?.toString(),
      grammar: node[ConfigKeys.component.grammar]?.toString(),
    );
  }
}
