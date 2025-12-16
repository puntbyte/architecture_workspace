import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/engines/configuration/hierarchy_parser.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class Definition {
  final List<String> types;
  final List<String> identifiers;
  final List<String> imports;
  final List<String> rewrites;
  final String? ref;
  final String? component;
  final List<Definition> arguments;
  final bool isWildcard;

  const Definition({
    this.types = const [],
    this.identifiers = const [],
    this.imports = const [],
    this.rewrites = const [],
    this.ref,
    this.component,
    this.arguments = const [],
    this.isWildcard = false,
  });

  factory Definition.fromDynamic(dynamic value) {
    if (value == null) return const Definition();

    if (value is String) {
      if (value == '*') return const Definition(isWildcard: true);
      return Definition(types: [value]);
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      final compRef = map.tryGetString(ConfigKeys.definition.component);
      if (compRef != null) return Definition(component: compRef);

      final refKey = map.tryGetString(ConfigKeys.definition.definition);
      if (refKey != null) return Definition(ref: refKey);

      // 'type' can be String or List<String>
      final typesList = map.getStringList(ConfigKeys.definition.type);
      if (typesList.contains('*')) return const Definition(isWildcard: true);

      final importsList = map.getStringList(ConfigKeys.definition.import);

      // FIX: Use the correct singular key for identifiers from the map
      final ids = map.getStringList(ConfigKeys.definition.identifier);

      final rewritesList = map.getStringList(ConfigKeys.definition.rewrite);

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
        types: typesList,
        identifiers: ids,
        imports: importsList,
        rewrites: rewritesList,
        arguments: args,
      );
    }

    return const Definition();
  }

  static Map<String, Definition> parseRegistry(Map<String, dynamic> map) {
    return HierarchyParser.parse<Definition>(
      yaml: map,
      factory: (id, node) => Definition.fromDynamic(node),
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

  String describe([Map<String, Definition>? registry]) {
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
