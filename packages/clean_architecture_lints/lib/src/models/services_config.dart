// lib/src/models/services_config.dart

import 'package:clean_architecture_lints/src/models/rules/dependency_injection_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// The parent configuration class for all service-related rules.
/// It acts as a namespace for configurations like dependency injection, logging, etc.
class ServicesConfig {
  /// The specific rules for dependency injection.
  final DependencyInjectionRule dependencyInjection;

  const ServicesConfig({
    required this.dependencyInjection,
  });

  factory ServicesConfig.fromMap(Map<String, dynamic> map) {
    return ServicesConfig(
      // Finds the 'dependency_injection' block in the YAML and parses it.
      dependencyInjection: DependencyInjectionRule.fromMap(map.getMap('dependency_injection')),
    );
  }
}
