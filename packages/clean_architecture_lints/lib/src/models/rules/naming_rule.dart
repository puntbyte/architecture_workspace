// lib/src/models/rules/naming_rule.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// Represents a single, complete naming rule with a syntactic pattern,
/// a forbidden anti-pattern, and an optional semantic grammar.
class NamingRule {
  final String pattern;
  final String? antipattern;
  final String? grammar;

  const NamingRule({
    required this.pattern,
    this.antipattern,
    this.grammar,
  });

  /// A factory to safely parse a naming rule from a YAML value, which can be
  /// either a simple String (treated as the pattern) or a complex Map.
  factory NamingRule.from(dynamic data, {required String defaultPattern}) {
    if (data is String) return NamingRule(pattern: data);

    if (data is Map<String, dynamic>) {
      return NamingRule(
        pattern: data.getString('pattern', orElse: defaultPattern),
        antipattern: data.getOptionalString('antipattern'),
        grammar: data.getOptionalString('grammar'),
      );
    }

    // Fallback for missing or invalid config, ensuring a valid pattern is always present.
    return NamingRule(pattern: defaultPattern);
  }
}
