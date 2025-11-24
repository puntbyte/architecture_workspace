import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// Represents a single type definition (name and optional import).
class TypeDefinition {
  final String name;
  final String? import;

  const TypeDefinition({required this.name, this.import});

  factory TypeDefinition.fromMap(Map<String, dynamic> map) {
    return TypeDefinition(
      name: map.asString(ConfigKey.type.name),
      import: map.asStringOrNull(ConfigKey.type.import),
    );
  }
}

/// Configuration for shared type definitions.
///
/// This class flattens the nested YAML structure into a map where keys are
/// dot-notated strings (e.g., "result.wrapper") and values are [TypeDefinition]s.
class TypeDefinitionsConfig {
  final Map<String, TypeDefinition> _types;

  const TypeDefinitionsConfig(this._types);

  /// Retrieves a type definition by its dot-notated key (e.g., 'exception.base').
  TypeDefinition? get(String key) => _types[key];

  factory TypeDefinitionsConfig.fromMap(Map<String, dynamic> map) {
    final rawMap = map.asMap(ConfigKey.root.typeDefinitions);
    final flattened = <String, TypeDefinition>{};

    void recurse(String parentKey, Map<String, dynamic> data) {
      for (final entry in data.entries) {
        final key = parentKey.isEmpty ? entry.key : '$parentKey.${entry.key}';
        final value = entry.value;

        if (value is Map<String, dynamic>) {
          // If it has a 'name' key, it's a definition. Otherwise, it's a category.
          if (value.containsKey(ConfigKey.type.name)) {
            flattened[key] = TypeDefinition.fromMap(value);
          } else {
            recurse(key, value);
          }
        }
      }
    }

    recurse('', rawMap);
    return TypeDefinitionsConfig(flattened);
  }
}
