// lib/src/models/services_config.dart

import 'package:clean_architecture_lints/src/models/rules/dependency_injection_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

class ServicesConfig {
  final DependencyInjectionRule dependencyInjection;

  const ServicesConfig({
    required this.dependencyInjection,
  });

  factory ServicesConfig.fromMap(Map<String, dynamic> map) {
    // THE DEFINITIVE FIX:
    // We must get the 'dependency_injection' sub-map from the 'services' map,
    // and pass THAT to the DependencyInjectionRule factory.
    return ServicesConfig(
      dependencyInjection: DependencyInjectionRule.fromMap(
        map.getMap('services').getMap('dependency_injection'),
      ),
    );
  }
}
