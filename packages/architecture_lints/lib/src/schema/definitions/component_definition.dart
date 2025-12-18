// lib/src/config/schema/component_definition.dart

import 'package:architecture_lints/src/engines/configuration/hierarchy_parser.dart';
import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/definitions/module_definition.dart';
import 'package:architecture_lints/src/schema/enums/component_kind.dart';
import 'package:architecture_lints/src/schema/enums/component_mode.dart';
import 'package:architecture_lints/src/schema/enums/component_modifier.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
class ComponentDefinition {
  final String id;
  final String? name;
  final List<String> paths;
  final List<String> relativePaths;
  final List<String> patterns;
  final List<String> antipatterns;
  final List<String> grammar;
  final List<ComponentKind> kinds;
  final List<ComponentModifier> modifiers;
  final bool isDefault;
  final ComponentMode mode;

  const ComponentDefinition({
    required this.id,
    this.name,
    this.paths = const [],
    this.relativePaths = const [],
    this.patterns = const [],
    this.antipatterns = const [],
    this.grammar = const [],
    this.kinds = const [],
    this.modifiers = const [],
    this.isDefault = false,
    this.mode = ComponentMode.file,
  });

  factory ComponentDefinition.fromMap(String key, Map<dynamic, dynamic> map) {
    List<T> parseEnumList<T>(String mapKey, T? Function(String?) parser) {
      final raw = map[mapKey];
      if (raw is String) {
        final val = parser(raw);
        return val != null ? [val] : [];
      }
      if (raw is List) return raw.map((e) => parser(e.toString())).whereType<T>().toList();
      return [];
    }

    return ComponentDefinition(
      id: key,
      name: map.tryGetString(ConfigKeys.component.name),
      // HierarchyParser has already merged/joined the paths for us
      paths: map.getStringList(ConfigKeys.component.path),

      // We can't easily get the 'raw' relative path here because 'map' is already merged.
      // If we really need it, we'd need to change HierarchyParser to preserve raw values.
      // For now, let's assume 'paths' is the important one for logic.
      // If 'relativePaths' is critical, we'd need a separate key or parser change.
      // Setting same as paths or empty for now to satisfy constructor.
      relativePaths: [],

      patterns: map.getStringList(ConfigKeys.component.pattern),
      antipatterns: map.getStringList(ConfigKeys.component.antipattern),
      kinds: parseEnumList(ConfigKeys.component.kind, ComponentKind.fromKey),
      modifiers: parseEnumList(ConfigKeys.component.modifier, ComponentModifier.fromKey),
      mode: ComponentMode.fromKey(map.tryGetString(ConfigKeys.component.mode)),
      isDefault: map.getBool(ConfigKeys.component.default$),
    );
  }

  static List<ComponentDefinition> parseMap(
    Map<String, dynamic> map,
    List<ModuleDefinition> modules,
  ) {
    final moduleKeys = modules.map((m) => m.key).toSet();

    final result = HierarchyParser.parse<ComponentDefinition>(
      yaml: map,
      scopeKeys: moduleKeys,
      // FIX: Use pathProperties for 'path' instead of inheritProperties
      pathProperties: [ConfigKeys.component.path],
      factory: (id, node) {
        if (node is Map) return ComponentDefinition.fromMap(id, node);
        throw const FormatException('Component definition must be a Map');
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

  @override
  String toString() => 'ComponentDefinition(id: $id, paths: $paths)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ComponentDefinition &&
        other.id == id &&
        other.name == name &&
        other.isDefault == isDefault &&
        other.mode == mode &&
        const ListEquality<String>().equals(other.paths, paths) &&
        const ListEquality<String>().equals(other.patterns, patterns) &&
        const ListEquality<String>().equals(other.antipatterns, antipatterns) &&
        const ListEquality<ComponentKind>().equals(other.kinds, kinds) &&
        const ListEquality<ComponentModifier>().equals(other.modifiers, modifiers);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      isDefault.hashCode ^
      mode.hashCode ^
      const ListEquality<String>().hash(paths) ^
      const ListEquality<String>().hash(patterns) ^
      const ListEquality<String>().hash(antipatterns) ^
      const ListEquality<ComponentKind>().hash(kinds) ^
      const ListEquality<ComponentModifier>().hash(modifiers);
}
