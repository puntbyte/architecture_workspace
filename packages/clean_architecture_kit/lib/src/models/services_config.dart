// lib/src/models/services_config.dart
import 'package:clean_architecture_kit/src/models/dependency_injection_config.dart';
import 'package:clean_architecture_kit/src/utils/json_map_extension.dart';

// You can now DELETE the `ServiceLocatorConfig` class.

/// The parent configuration class for all service-related rules.
class ServicesConfig {
  final DependencyInjectionConfig dependencyInjection;

  const ServicesConfig({
    required this.dependencyInjection,
  });

  factory ServicesConfig.fromMap(Map<String, dynamic> map) {
    return ServicesConfig(
      dependencyInjection: DependencyInjectionConfig.fromMap(map.getMap('dependency_injection')),
    );
  }
}
