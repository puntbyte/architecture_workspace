// lib/src/schema/definitions/type_definition.dart

import 'package:architecture_lints/src/engines/configuration/hierarchy_parser.dart';
import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class TypeDefinition {
  final List<String> types;
  final List<String> identifiers;
  final List<String> imports;
  final List<String> rewrites;
  final String? ref;
  final String? component;
  final List<TypeDefinition> arguments;
  final bool isWildcard;

  const TypeDefinition({
    this.types = const [],
    this.identifiers = const [],
    this.imports = const [],
    this.rewrites = const [],
    this.ref,
    this.component,
    this.arguments = const [],
    this.isWildcard = false,
  });

  factory TypeDefinition.fromDynamic(dynamic value) {
    if (value == null) return const TypeDefinition();

    // 1. Shorthand String -> Single Type
    if (value is String) {
      if (value == '*') return const TypeDefinition(isWildcard: true);
      return TypeDefinition(types: [value]);
    }

    // 2. Map
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      final compRef = map.tryGetString(ConfigKeys.definition.component);
      if (compRef != null) return TypeDefinition(component: compRef);

      final refKey = map.tryGetString(ConfigKeys.definition.definition);
      if (refKey != null) return TypeDefinition(ref: refKey);

      final typeName = map.tryGetString(ConfigKeys.definition.type);
      if (typeName == '*') return const TypeDefinition(isWildcard: true);

      // 'type' can be String or List<String>
      final typesList = map.getStringList(ConfigKeys.definition.type);
      if (typesList.contains('*')) return const TypeDefinition(isWildcard: true);

      final importsList = map.getStringList(ConfigKeys.definition.import);
      final ids = map.getStringList(ConfigKeys.definition.identifier);
      final rewritesList = map.getStringList(ConfigKeys.definition.rewrite);

      final rawArgs = map[ConfigKeys.definition.argument];
      final args = <TypeDefinition>[];
      if (rawArgs != null) {
        if (rawArgs is List) {
          args.addAll(rawArgs.map(TypeDefinition.fromDynamic));
        } else {
          args.add(TypeDefinition.fromDynamic(rawArgs));
        }
      }

      return TypeDefinition(
        types: typesList,
        identifiers: ids,
        imports: importsList,
        rewrites: rewritesList,
        arguments: args,
      );
    }

    return const TypeDefinition();
  }

  static Map<String, TypeDefinition> parseRegistry(Map<String, dynamic> map) {
    return HierarchyParser.parse<TypeDefinition>(
      yaml: map,
      factory: (id, node) => TypeDefinition.fromDynamic(node),
      inheritProperties: [ConfigKeys.definition.import],
      cascadeProperties: [ConfigKeys.definition.import],
      shorthandKey: ConfigKeys.definition.type,
      shouldParseNode: (node) {
        if (node is String) return true;
        if (node is Map) {
          return node.containsKey(ConfigKeys.definition.type) ||
              node.containsKey(ConfigKeys.definition.identifier) ||
              node.containsKey(ConfigKeys.definition.definition) ||
              node.containsKey(ConfigKeys.definition.component) ||
              node.containsKey(ConfigKeys.definition.argument);
        }
        return false;
      },
    );
  }

  // Backward compatibility getters

  String? get type => types.isNotEmpty ? types.first : null;

  String? get import => imports.isNotEmpty ? imports.first : null;

  Map<String, dynamic> toMap() => {
    'type': type,
    'types': types,
    'import': import,
    'imports': imports,
    'rewrites': rewrites,
    'ref': ref,
    'component': component,
    'isWildcard': isWildcard,
  };

  String describe([Map<String, TypeDefinition>? registry]) {
    if (isWildcard) return 'Any';
    if (component != null) return 'Component($component)';
    if (ref != null) {
      if (registry != null) {
        final resolved = registry[ref];
        if (resolved != null) return resolved.describe(registry);
      }
      return 'Ref($ref)';
    }
    if (identifiers.isNotEmpty) return identifiers.join('|');
    if (types.isNotEmpty) {
      final baseName = types.join('|');
      if (arguments.isNotEmpty) {
        final argsDescription = arguments.map((arg) => arg.describe(registry)).join(', ');
        return '$baseName<$argsDescription>';
      }
      return baseName;
    }
    return 'Unknown Definition';
  }

  @override
  String toString() => describe();
}
