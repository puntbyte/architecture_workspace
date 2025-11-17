// lib/src/models/rules/dependency_injection_rule.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// A strongly-typed representation of the `dependency_injection` block,
/// defining rules for DI-related lints and code generation.
class DependencyInjectionRule {
  /// The names of service locator functions to flag (e.g., 'getIt', 'locator').
  final List<String> serviceLocatorNames;

  const DependencyInjectionRule({
    required this.serviceLocatorNames,
  });

  factory DependencyInjectionRule.fromMap(Map<String, dynamic> map) {
    return DependencyInjectionRule(
      // Correctly parse the 'names' key and provide a default list.
      serviceLocatorNames: map.getList('service_locator_names', orElse: ['getIt', 'locator', 'sl']),
    );
  }
}
