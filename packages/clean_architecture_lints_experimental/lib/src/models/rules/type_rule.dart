// lib/src/models/rules/type_rule.dart

part of '../configs/type_config.dart';

/// Represents a single type definition (name and optional import).
class TypeRule {
  final String key;
  final String name;
  final String? import;

  const TypeRule({
    required this.key,
    required this.name,
    this.import,
  });

  factory TypeRule.fromMap(
    Map<String, dynamic> map, {
    String? defaultImport,
  }) {
    return TypeRule(
      key: map.asString(ConfigKey.type.key),
      name: map.asString(ConfigKey.type.name),
      // Use specific import if present, otherwise fallback to default (base) import
      import: map.asStringOrNull(ConfigKey.type.import) ?? defaultImport,
    );
  }
}
