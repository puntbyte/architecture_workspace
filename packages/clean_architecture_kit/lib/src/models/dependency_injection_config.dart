// lib/src/models/dependency_injection_config.dart
import 'package:clean_architecture_kit/src/utils/json_map_extension.dart';

/// Represents a single annotation to be added during code generation.
class AnnotationConfig {
  final String importPath;
  final String annotationText;

  const AnnotationConfig({required this.importPath, required this.annotationText});

  factory AnnotationConfig.fromMap(Map<String, dynamic> map) {
    return AnnotationConfig(
      importPath: map.getString('import_path'),
      annotationText: map.getString('annotation_text'),
    );
  }
}

/// A strongly-typed representation of the `dependency_injection` block.
/// This now holds ALL DI-related configurations.
class DependencyInjectionConfig {
  /// The names of service locator functions to flag (e.g., 'getIt', 'locator').
  final List<String> serviceLocatorNames;

  /// Annotations to be added to generated UseCase classes.
  final List<AnnotationConfig> useCaseAnnotations;

  const DependencyInjectionConfig({
    required this.serviceLocatorNames,
    required this.useCaseAnnotations,
  });

  factory DependencyInjectionConfig.fromMap(Map<String, dynamic> map) {
    final useCaseList = (map['use_case_annotations'] as List<dynamic>?) ?? [];
    return DependencyInjectionConfig(
      // Parse the service locator names from this block.
      serviceLocatorNames: map.getList('service_locator_names', ['getIt', 'locator', 'sl']),
      useCaseAnnotations: useCaseList
          .whereType<Map<String, dynamic>>()
          .map(AnnotationConfig.fromMap)
          .toList(),
    );
  }
}
