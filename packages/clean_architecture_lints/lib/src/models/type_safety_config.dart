// lib/src/models/type_safety_config.dart

import 'package:clean_architecture_lints/src/models/rules/type_safety_rule.dart';

/// The parent configuration class for all type safety rules.
class TypeSafetyConfig {
  /// A single, unified list of all type safety rules.
  final List<TypeSafetyRule> rules;

  const TypeSafetyConfig({required this.rules});

  factory TypeSafetyConfig.fromMap(Map<String, dynamic> map) {
    // The key is now `type_safeties` as per your design.
    final ruleList = (map['type_safeties'] as List<dynamic>?) ?? [];

    return TypeSafetyConfig(
      rules: ruleList
          .whereType<Map<String, dynamic>>()
          .map(TypeSafetyRule.tryFromMap)
          .whereType<TypeSafetyRule>()
          .toList(),
    );
  }
}
