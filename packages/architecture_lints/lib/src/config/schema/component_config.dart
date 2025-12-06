import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/parsing/hierarchy_parser.dart';
import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ComponentConfig {
  final String id;
  final String? name;
  final List<String> paths;
  final List<String> patterns;
  final List<String> antipatterns;
  final List<String> grammar;
  final bool isDefault;

  const ComponentConfig({
    required this.id,
    this.name,
    this.paths = const [],
    this.patterns = const [],
    this.antipatterns = const [],
    this.grammar = const [],
    this.isDefault = false,
  });

  factory ComponentConfig.fromMap(String key, Map<dynamic, dynamic> map) {
    return ComponentConfig(
      id: key,
      name: map.tryGetString(ConfigKeys.component.name),
      paths: map.getStringList(ConfigKeys.component.path),
      patterns: map.getStringList(ConfigKeys.component.pattern),
      antipatterns: map.getStringList(ConfigKeys.component.antipattern),
      grammar: map.getStringList(ConfigKeys.component.grammar),
      isDefault: map.getBool(ConfigKeys.component.default$),
    );
  }

  static List<ComponentConfig> parseMap(
      Map<String, dynamic> map,
      List<ModuleConfig> modules,
      ) {
    final moduleKeys = modules.map((m) => m.key).toSet();

    final result = HierarchyParser.parse<ComponentConfig>(
      yaml: map,
      scopeKeys: moduleKeys,
      // Parent Inheritance: Child inherits 'path' from parent if missing
      inheritProperties: [ConfigKeys.component.path],
      factory: (id, node) {
        if (node is Map) return ComponentConfig.fromMap(id, node);
        throw FormatException('Component definition must be a Map');
      },
      shouldParseNode: (node) {
        if (node is! Map) return false;
        return node.containsKey(ConfigKeys.component.path) ||
            node.containsKey(ConfigKeys.component.pattern) ||
            node.containsKey(ConfigKeys.component.grammar) ||
            node.containsKey(ConfigKeys.component.antipattern);
      },
    );

    return result.values.toList();
  }

  String get displayName {
    if (name != null) return name!;
    return id
        .split('.')
        .where((s) => s.isNotEmpty)
        .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
        .join(' ');
  }
}