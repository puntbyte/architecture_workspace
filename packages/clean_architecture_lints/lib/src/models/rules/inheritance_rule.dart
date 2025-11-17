// lib/src/models/rules/inheritance_rule.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// Represents a single, user-defined inheritance rule.
class InheritanceRule {
  final String on;
  final List<InheritanceDetail> required;
  final List<InheritanceDetail> forbidden;
  final List<InheritanceDetail> suggested;

  const InheritanceRule({
    required this.on,
    this.required = const [],
    this.forbidden = const [],
    this.suggested = const [],
  });

  /// A failable factory. Returns null if the essential 'on' key is missing.
  static InheritanceRule? tryFromMap(Map<String, dynamic> map) {
    final on = map.getString('on');
    // THE DEFINITIVE FIX (Part 1): If 'on' is missing, the rule is invalid.
    if (on.isEmpty) {
      return null;
    }

    List<InheritanceDetail> parseDetails(String key) {
      final data = map[key];
      if (data is Map<String, dynamic>) {
        final detail = InheritanceDetail.tryFromMap(data);
        return detail != null ? [detail] : [];
      }
      if (data is List) {
        return data.whereType<Map<String, dynamic>>()
            .map(InheritanceDetail.tryFromMap)
            .whereType<InheritanceDetail>()
            .toList();
      }
      return [];
    }

    return InheritanceRule(
      on: on,
      required: parseDetails('required'),
      forbidden: parseDetails('forbidden'),
      suggested: parseDetails('suggested'),
    );
  }
}

/// Represents the details of a single base class in an inheritance rule.
class InheritanceDetail {
  final String name;
  final String import;
  const InheritanceDetail({required this.name, required this.import});

  static InheritanceDetail? tryFromMap(Map<String, dynamic> map) {
    final name = map.getString('name');
    final import = map.getString('import');
    if (name.isEmpty || import.isEmpty) return null;
    return InheritanceDetail(name: name, import: import);
  }
}
