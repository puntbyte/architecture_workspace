// lib/src/models/details/inheritance_detail.dart

part of '../inheritances_config.dart';

/// Represents the details of a single base class in an inheritance rule.
class InheritanceDetail {
  final String? name;
  final String? import;
  final String? component;

  const InheritanceDetail({
    this.name,
    this.import,
    this.component,
  });

  /// Creates an instance from a map, returning null if required fields are missing.
  static InheritanceDetail? tryFromMap(Map<String, dynamic> map) {
    // ConfigKey and extensions are available via the parent file's imports.
    final name = map.asStringOrNull(ConfigKey.rule.name);
    final component = map.asStringOrNull(ConfigKey.rule.component);

    // Must have either a class Name OR a Component reference
    if (name == null && component == null) return null;

    return InheritanceDetail(
      name: name,
      import: map.asStringOrNull(ConfigKey.rule.import),
      component: component,
    );
  }
}