// lib/src/config/schema/inheritance_policy.dart

import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class InheritancePolicy {
  final List<String> onIds;
  final List<TypeDefinition> required;
  final List<TypeDefinition> allowed;
  final List<TypeDefinition> forbidden;

  const InheritancePolicy({
    required this.onIds,
    required this.required,
    required this.allowed,
    required this.forbidden,
  });

  factory InheritancePolicy.fromMap(Map<dynamic, dynamic> map) => InheritancePolicy(
    onIds: map.getStringList(ConfigKeys.inheritance.on),
    required: _parseDefinitionList(map[ConfigKeys.inheritance.required]),
    allowed: _parseDefinitionList(map[ConfigKeys.inheritance.allowed]),
    forbidden: _parseDefinitionList(map[ConfigKeys.inheritance.forbidden]),
  );

  /// Parses a list of Maps into a list of InheritanceConfigs.
  static List<InheritancePolicy> parseList(List<Map<String, dynamic>> list) =>
      list.map(InheritancePolicy.fromMap).toList();

  static List<TypeDefinition> _parseDefinitionList(dynamic value) {
    if (value == null) return const [];

    // Case 1: Standard List (e.g. required: [ 'Entity', { type: 'Base' } ])
    if (value is List) return value.map(TypeDefinition.fromDynamic).toList();

    // Case 2: Map Shorthand (e.g. required: { definition: ['usecase.unary', 'usecase.nullary'] })
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      // Expansion Logic:
      // Since Definition.ref is singular, we must expand a list of refs
      // into multiple Definition objects.
      final defs = map[ConfigKeys.definition.definition];
      if (defs is List) return defs.map((ref) => TypeDefinition(ref: ref.toString())).toList();

      // Note: We do NOT need to expand 'type': ['A', 'B'] here,
      // because Definition.fromDynamic handles 'type' as a list internally now.

      // Fallback: Parse as a single definition object
      return [TypeDefinition.fromDynamic(value)];
    }

    // Case 3: Single String shorthand (e.g. required: 'Entity')
    return [TypeDefinition.fromDynamic(value)];
  }
}
