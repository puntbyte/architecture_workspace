// lib/src/models/annotations_config.dart

import 'package:clean_architecture_lints/src/models/rules/annotation_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';

/// The parent configuration class for all annotation rules.
class AnnotationsConfig {
  /// A list of all annotation rules defined in `analysis_options.yaml`.
  final List<AnnotationRule> rules;

  const AnnotationsConfig({required this.rules});

  /// A helper to find the specific rule for a given architectural component ID.
  AnnotationRule? ruleFor(String componentId) {
    return rules.firstWhereOrNull((rule) => rule.on == componentId);
  }

  /// A convenient helper for code generators to find all annotations
  /// that are required for a specific component.
  //
  // THE DEFINITIVE FIX IS HERE: This method was missing.
  List<AnnotationDetail> requiredFor(String componentId) {
    // Safely find the rule and return its `required` list, or an empty list if not found.
    return ruleFor(componentId)?.required ?? [];
  }

  /// The factory constructor that parses the `annotations` block from the YAML.
  factory AnnotationsConfig.fromMap(Map<String, dynamic> map) {
    // The key in the YAML is `annotations`, which is a list of rule maps.
    final ruleList = (map['annotations'] as List<dynamic>?) ?? [];

    return AnnotationsConfig(
      rules: ruleList
          .whereType<Map<String, dynamic>>()
          .map(AnnotationRule.tryFromMap)
          .whereType<AnnotationRule>() // Filter out any nulls from malformed rules
          .toList(),
    );
  }
}
