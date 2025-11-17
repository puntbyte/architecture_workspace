// lib/src/models/rules/type_safety_rule.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// An enum to represent what part of a method signature a rule targets.
enum TypeSafetyTarget { returnType, parameter, unknown }

/// Represents a single, unified type safety rule.
class TypeSafetyRule {
  /// The architectural components to apply the rule to.
  final List<String> on;

  /// The part of the signature to check ('return' or 'parameter').
  final TypeSafetyTarget check;

  /// The unsafe type to look for (e.g., 'Future', 'int').
  final String unsafeType;

  /// The safe type to suggest as a replacement (e.g., 'FutureEither', 'IntId').
  final String safeType;

  /// The import path for the safe type.
  final String? import;

  /// An optional identifier to target specific parameters (e.g., 'id').
  final String? identifier;

  const TypeSafetyRule({
    required this.on,
    required this.check,
    required this.unsafeType,
    required this.safeType,
    this.import,
    this.identifier,
  });

  /// A failable factory. Returns null if essential keys are missing.
  static TypeSafetyRule? tryFromMap(Map<String, dynamic> map) {
    final on = map.getList('on');
    final unsafeType = map.getString('unsafe_type');
    final safeType = map.getString('safe_type');
    final checkStr = map.getString('check');

    TypeSafetyTarget check;
    switch (checkStr) {
      case 'return':
        check = TypeSafetyTarget.returnType;
      case 'parameter':
        check = TypeSafetyTarget.parameter;
      default:
        check = TypeSafetyTarget.unknown;
    }

    if (on.isEmpty || unsafeType.isEmpty || safeType.isEmpty || check == TypeSafetyTarget.unknown) {
      return null;
    }

    return TypeSafetyRule(
      on: on,
      check: check,
      unsafeType: unsafeType,
      safeType: safeType,
      import: map.getOptionalString('import'),
      identifier: map.getOptionalString('identifier'),
    );
  }
}
