// lib/src/models/rules/naming_rule.dart

import 'package:clean_architecture_kit/src/utils/extensions/json_map_extension.dart';

/// Represents a single naming rule with allowed and forbidden patterns.
class NamingRule {
  final String pattern;
  final List<String> antiPatterns;

  const NamingRule({required this.pattern, this.antiPatterns = const []});

  factory NamingRule.from(dynamic data, String defaultPattern) {
    if (data is String) return NamingRule(pattern: data);

    if (data is Map<String, dynamic>) {
      return NamingRule(
        pattern: data.getString('pattern', defaultPattern),
        antiPatterns: data.getList('anti_pattern'), // CORRECTED
      );
    }

    return NamingRule(pattern: defaultPattern);
  }
}
