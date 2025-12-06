// lib/src/config/schema/definition.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/parsing/hierarchy_parser.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class Definition {
  final String? type;
  final List<String> types;
  final List<String> identifiers;
  final String? import;
  final String? ref;
  final String? component;
  final List<Definition> arguments;
  final bool isWildcard;

  const Definition({
    this.type,
    this.types = const [],
    this.identifiers = const [],
    this.import,
    this.ref,
    this.component,
    this.arguments = const [],
    this.isWildcard = false,
  });

  /// Factory to parse a definition value.
  /// Note: Context/Inheritance is handled by [HierarchyParser] merging properties into [value] if
  /// it is a Map.
  factory Definition.fromDynamic(dynamic value) {
    if (value == null) return const Definition();

    // 1. Shorthand String
    if (value is String) {
      if (value == '*') return const Definition(isWildcard: true);
      return Definition(type: value);
    }

    // 2. Map
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      final compRef = map.tryGetString(ConfigKeys.definition.component);
      if (compRef != null) return Definition(component: compRef);

      final refKey = map.tryGetString(ConfigKeys.definition.definition);
      if (refKey != null) return Definition(ref: refKey);

      final typeName = map.tryGetString(ConfigKeys.definition.type);
      if (typeName == '*') return const Definition(isWildcard: true);

      // Parse List of Types (reuse 'type' key)
      final rawType = map[ConfigKeys.definition.type];
      final typesList = <String>[];
      if (rawType is List) typesList.addAll(rawType.map((e) => e.toString()));
      if (typeName != null) typesList.add(typeName);

      final import = map.tryGetString(ConfigKeys.definition.import);

      final rawIds = map[ConfigKeys.definition.identifiers];
      final ids = <String>[];
      if (rawIds is String) ids.add(rawIds);
      if (rawIds is List) ids.addAll(rawIds.map((e) => e.toString()));

      final rawArgs = map[ConfigKeys.definition.argument];
      final args = <Definition>[];
      if (rawArgs != null) {
        if (rawArgs is List) {
          args.addAll(rawArgs.map(Definition.fromDynamic));
        } else {
          args.add(Definition.fromDynamic(rawArgs));
        }
      }

      return Definition(
        type: typeName,
        types: typesList,
        identifiers: ids,
        import: import,
        arguments: args,
      );
    }

    return const Definition();
  }

  /// Parses the 'definitions' registry using HierarchyParser.
  static Map<String, Definition> parseRegistry(Map<String, dynamic> map) {
    return HierarchyParser.parse<Definition>(
      yaml: map,
      factory: (id, node) => Definition.fromDynamic(node),
      cascadeProperties: [ConfigKeys.definition.import],
      shorthandKey: ConfigKeys.definition.type,
      // NEW: Expands string shorthands to {type: string}
      shouldParseNode: (node) {
        if (node is String) return true;
        if (node is Map) {
          return node.containsKey(ConfigKeys.definition.type) ||
              node.containsKey(ConfigKeys.definition.identifiers) ||
              node.containsKey(ConfigKeys.definition.definition) ||
              node.containsKey(ConfigKeys.definition.component) ||
              node.containsKey(ConfigKeys.definition.argument);
        }
        return false;
      },
    );
  }

  @override
  String toString() {
    if (isWildcard) return '*';
    if (ref != null) return 'Ref($ref)';
    if (component != null) return 'Component($component)';

    final base = type ?? (identifiers.isNotEmpty ? identifiers.first : '?');
    if (arguments.isEmpty) return base;

    return '$base<${arguments.join(', ')}>';
  }
}
