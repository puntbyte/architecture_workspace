import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/engines/resolution/type_resolver.dart';
import 'package:architecture_lints/src/schema/constraints/type_safety_constraint.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:architecture_lints/src/schema/policies/type_safety_policy.dart';

mixin TypeSafetyLogic {
  /// Checks if [type] matches any constraint in the [constraintList].
  bool matchesAnyConstraint(
    DartType type,
    List<TypeSafetyConstraint> constraintList,
    TypeResolver typeResolver,
  ) => constraintList.any((c) => matchesConstraint(type, c, typeResolver));

  /// Checks if [type] is explicitly forbidden by the policy.
  bool isExplicitlyForbidden({
    required DartType type,
    required TypeSafetyPolicy configRule,
    required String kind,
    required TypeResolver typeResolver,
    String? paramName,
  }) {
    final forbiddenConstraints = configRule.forbidden.where((c) {
      if (c.kind != kind) return false;

      // FIX: Use smart matching logic
      if (kind == 'parameter' && paramName != null) {
        if (!matchesParameterName(c, paramName)) return false;
      }

      return true;
    }).toList();

    return matchesAnyConstraint(type, forbiddenConstraints, typeResolver);
  }

  /// Smart matching for parameter names.
  /// 1. If pattern contains regex symbols, treat as Regex.
  /// 2. Otherwise, treat as Exact Match.
  bool matchesParameterName(TypeSafetyConstraint constraint, String paramName) {
    if (constraint.kind != 'parameter') return false;

    final pattern = constraint.identifier;
    if (pattern == null) return true; // Applies to all parameters if no identifier specified

    // A. Regex Match
    if (_isRegex(pattern)) {
      return RegExp(pattern).hasMatch(paramName);
    }

    // B. Exact Match (Fixes 'id' matching 'middleName')
    return pattern == paramName;
  }

  bool _isRegex(String str) {
    return str.contains(RegExp(r'[\^\$\.\*\+\?\|\(\)\[\]\{\}\\]'));
  }

  bool matchesConstraint(
    DartType type,
    TypeSafetyConstraint constraint,
    TypeResolver typeResolver,
  ) {
    // 1. Definition Match
    if (constraint.definitions.isNotEmpty) {
      for (final defId in constraint.definitions) {
        final def = typeResolver.registry[defId];
        if (def == null) continue;

        // Check using ANY mode (Alias OR Canonical)
        if (typeResolver.matches(type, def)) return true;
      }
    }

    // 2. Component Match
    if (constraint.component != null) {
      if (typeResolver.matchesComponent(type, constraint.component!)) return true;
    }

    // 3. Raw Type Match
    if (constraint.types.isNotEmpty) {
      final name = type.element?.name ?? type.getDisplayString();
      if (constraint.types.contains(name)) return true;
    }

    return false;
  }

  String describeConstraint(TypeSafetyConstraint c, Map<String, TypeDefinition> registry) {
    if (c.definitions.isNotEmpty) {
      return c.definitions
          .map((key) {
            final def = registry[key];
            return def?.describe(registry) ?? key;
          })
          .join(' or ');
    }
    if (c.types.isNotEmpty) return c.types.join(' or ');
    if (c.component != null) return 'Component: ${c.component}';

    return 'Defined Rule';
  }
}
