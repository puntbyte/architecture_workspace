// lib/src/models/naming_config.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/rules/naming_rule.dart';

/// A strongly-typed representation of the entire `naming_conventions` block.
///
/// It uses a map keyed by the `ArchComponent` enum for type-safe, flexible,
/// and scalable access to naming rules.
class NamingConfig {
  /// A map from an architectural component to its specific naming rule.
  final Map<ArchComponent, NamingRule> rules;

  const NamingConfig({required this.rules});

  /// A safe way to get the rule for a specific architectural component.
  NamingRule? getRuleFor(ArchComponent component) => rules[component];

  /// The factory constructor is the parsing engine. It iterates through all known
  /// architectural components and parses their corresponding rule from the raw map,
  /// applying a hardcoded default if the rule is not specified in the YAML.
  factory NamingConfig.fromMap(Map<String, dynamic> map) {
    final ruleMap = <ArchComponent, NamingRule>{};

    // Iterate through all possible ArchComponent values defined in the enum.
    for (final component in ArchComponent.values) {
      if (component == ArchComponent.unknown) continue;

      // Use the component's unique `id` to look up its rule in the YAML map.
      final ruleData = map[component.id];

      // Get the hardcoded default pattern for this component.
      final defaultPattern = _getDefaultPatternFor(component);

      // Create the NamingRule from the found data or fall back to the default.
      ruleMap[component] = NamingRule.from(ruleData, defaultPattern: defaultPattern);
    }

    return NamingConfig(rules: ruleMap);
  }

  /// A helper that provides the hardcoded default pattern for each component.
  /// This ensures the linter has a valid pattern to work with even if the user
  /// provides a minimal configuration.
  static String _getDefaultPatternFor(ArchComponent component) {
    return switch (component) {
      ArchComponent.entity => '{{name}}',
      ArchComponent.model => '{{name}}Model',
      ArchComponent.usecase => '{{name}}',
      ArchComponent.usecaseParameter => '_{{name}}Param',
      ArchComponent.contract => '{{name}}Repository',
      ArchComponent.repository => '{{prefix}}{{name}}Repository',
      ArchComponent.source => '{{name}}DataSource',
      ArchComponent.sourceImplementation => 'Default{{name}}DataSource',
      ArchComponent.manager => '{{name}}Bloc',
      ArchComponent.event => '{{name}}Event',
      ArchComponent.state => '{{name}}State',
      // Implementations for events/states often have varied names, so a simple
      // `{{name}}` is a safe and flexible default.
      _ => '{{name}}',
    };
  }
}
