// lib/src/models/rules/annotation_rule.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// Represents a single annotation's details (its text and import path).
/// Represents the details of a single annotation (its text and import path).
class AnnotationDetail {
  final String text;
  final String? import;
  final String? message; // For suggested annotations

  const AnnotationDetail({
    required this.text,
    this.import,
    this.message,
  });

  /// A failable factory. Returns null if the 'text' key is missing or empty.
  static AnnotationDetail? tryFromMap(Map<String, dynamic> map) {
    final text = map.getString('text');
    if (text.isEmpty) return null;

    return AnnotationDetail(
      text: text,
      import: map.getOptionalString('import'),
      message: map.getOptionalString('message'),
    );
  }
}

/// Represents a single, complete annotation rule for an architectural component.
class AnnotationRule {
  /// The architectural component to apply the rule to (e.g., 'use_case').
  final String on;
  final List<AnnotationDetail> required;
  final List<AnnotationDetail> forbidden;
  final List<AnnotationDetail> suggested;

  const AnnotationRule({
    required this.on,
    this.required = const [],
    this.forbidden = const [],
    this.suggested = const [],
  });

  /// A failable factory. Returns null if the 'on' key is missing or empty.
  static AnnotationRule? tryFromMap(Map<String, dynamic> map) {
    final on = map.getString('on');
    if (on.isEmpty) return null;

    // Helper to parse a key that can be a single map or a list of maps.
    List<AnnotationDetail> parseDetails(String key) {
      final data = map[key];
      if (data is Map<String, dynamic>) {
        final detail = AnnotationDetail.tryFromMap(data);
        return detail != null ? [detail] : [];
      }
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(AnnotationDetail.tryFromMap)
            .whereType<AnnotationDetail>()
            .toList();
      }
      return [];
    }

    return AnnotationRule(
      on: on,
      required: parseDetails('required'),
      forbidden: parseDetails('forbidden'),
      suggested: parseDetails('suggested'),
    );
  }
}