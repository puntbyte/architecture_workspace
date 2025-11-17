// lib/src/models/rules/dependency_injection_rule.dart

// lib/src/models/rules/dependency_injection_rule.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

class DependencyInjectionRule {
  final List<String> serviceLocatorNames;

  const DependencyInjectionRule({
    required this.serviceLocatorNames,
  });

  factory DependencyInjectionRule.fromMap(Map<String, dynamic> map) {
    // This code is now correct because it receives the correct sub-map.
    return DependencyInjectionRule(
      serviceLocatorNames: map.getList('service_locator_names', orElse: ['getIt', 'locator', 'sl']),
    );
  }
}
