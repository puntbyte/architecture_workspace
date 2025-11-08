// lib/src/models/type_safety_config.dart
import 'package:clean_architecture_kit/src/utils/json_map_extension.dart';

/// A rule for enforcing a specific return type.
class ReturnRule {
  final String type;
  final List<String> where;
  final String? importPath;

  const ReturnRule({
    required this.type,
    required this.where,
    this.importPath,
  });

  /// A failable factory. Returns null if essential keys are missing.
  static ReturnRule? tryFromMap(Map<String, dynamic> map) {
    final type = map.getString('type');
    final where = map.getList('where');

    // A rule is invalid without a `type` and at least one `where` location.
    if (type.isEmpty || where.isEmpty) return null;

    return ReturnRule(
      type: type,
      where: where,
      importPath: map.getOptionalString('import'), // Use the new optional getter
    );
  }
}

/// A rule for enforcing a specific parameter type.
class ParameterRule {
  final String type;
  final List<String> where;
  final String? importPath;
  final String? identifier;

  const ParameterRule({
    required this.type,
    required this.where,
    this.importPath,
    this.identifier,
  });

  /// A failable factory. Returns null if essential keys are missing.
  static ParameterRule? tryFromMap(Map<String, dynamic> map) {
    final type = map.getString('type');
    final where = map.getList('where');

    if (type.isEmpty || where.isEmpty) return null;

    return ParameterRule(
      type: type,
      where: where,
      importPath: map.getOptionalString('import'),
      identifier: map.getOptionalString('identifier'), // Use the new optional getter
    );
  }
}

/// The parent configuration class for all type safety rules.
class TypeSafetyConfig {
  final List<ReturnRule> returns;
  final List<ParameterRule> parameters;

  const TypeSafetyConfig({required this.returns, required this.parameters});

  factory TypeSafetyConfig.fromMap(Map<String, dynamic> map) {
    final returnsList = (map['returns'] as List<dynamic>?) ?? [];
    final paramsList = (map['parameters'] as List<dynamic>?) ?? [];

    return TypeSafetyConfig(
      returns: returnsList
          .whereType<Map<String, dynamic>>()
          .map(ReturnRule.tryFromMap)
          .whereType<ReturnRule>()
          .toList(),

      parameters: paramsList
          .whereType<Map<String, dynamic>>()
          .map(ParameterRule.tryFromMap)
          .whereType<ParameterRule>()
          .toList(),
    );
  }
}
