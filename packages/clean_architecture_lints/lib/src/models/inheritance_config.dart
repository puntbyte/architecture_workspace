// lib/src/models/inheritance_config.dart

import 'package:clean_architecture_lints/src/models/rules/inheritance_rule.dart';

/// The parent configuration class for all custom, user-defined inheritance rules.
class InheritanceConfig {
  final List<InheritanceRule> rules;
  const InheritanceConfig({required this.rules});

  factory InheritanceConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = (map['inheritances'] as List<dynamic>?) ?? [];
    return InheritanceConfig(
      // THE DEFINITIVE FIX (Part 2): Use the failable factory and filter out nulls.
      rules: ruleList
          .whereType<Map<String, dynamic>>()
          .map(InheritanceRule.tryFromMap)
          .whereType<InheritanceRule>() // This filters out any null results.
          .toList(),
    );
  }
}
