// lib/src/models/configs/type_config.dart

import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part '../rules/type_rule.dart';

/// Configuration for shared type definitions.
///
/// This class flattens the nested YAML structure into a map where keys are
/// dot-notated strings (e.g., "result.wrapper") and values are [TypeRule]s.
class TypeConfig {
  final Map<String, TypeRule> _types;

  const TypeConfig(this._types);

  /// Retrieves a type definition by its dot-notated key (e.g., 'exception.base').
  TypeRule? get(String key) => _types[key];

  factory TypeConfig.fromMap(Map<String, dynamic> map) {
    final rawMap = map.asMap(ConfigKey.root.typeDefinitions);
    final flattened = <String, TypeRule>{};

    void recurse(String parentKey, Map<String, dynamic> data) {
      for (final entry in data.entries) {
        final key = parentKey.isEmpty ? entry.key : '$parentKey.${entry.key}';
        final value = entry.value;

        if (value is Map<String, dynamic>) {
          // If it has a 'name' key, it's a definition. Otherwise, it's a category.
          if (value.containsKey(ConfigKey.type.name)) {
            flattened[key] = TypeRule.fromMap(value);
          } else {
            recurse(key, value);
          }
        }
      }
    }

    recurse('', rawMap);
    return TypeConfig(flattened);
  }
}
