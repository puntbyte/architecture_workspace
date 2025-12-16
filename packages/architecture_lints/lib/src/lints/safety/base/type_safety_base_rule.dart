// lib/src/lints/safety/base/type_safety_base_rule.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/policies/type_safety_policy.dart';
import 'package:architecture_lints/src/schema/constraints/type_safety_constraint.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/lints/safety/logic/type_safety_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class TypeSafetyBaseRule extends ArchitectureRule
    with TypeSafetyLogic, InheritanceLogic {
  const TypeSafetyBaseRule({required super.code});

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    if (component == null) return;

    // 1. Centralized Config Filtering
    // Uses ComponentContext to check matchesAny against the rule IDs
    final rules = config.typeSafeties.where((rule) {
      return component.matchesAny(rule.onIds);
    }).toList();

    if (rules.isEmpty) return;

    // 2. Centralized AST Traversal
    context.registry.addMethodDeclaration((node) {
      // --- Handle Return Type ---
      final returnType = node.returnType?.type;
      if (returnType != null) {
        checkReturn(
          node: node,
          type: returnType,
          rules: rules,
          config: config,
          fileResolver: fileResolver,
          reporter: reporter,
        );
      }

      // --- Handle Parameters ---
      final params = node.parameters;
      if (params != null) {
        for (final param in params.parameters) {
          // Centralized Element Extraction (Handles API changes in one place)
          final element = param.declaredFragment?.element;
          final type = element?.type;
          final name = param.name?.lexeme;

          if (type != null && name != null) {
            checkParameter(
              node: param,
              type: type,
              paramName: name,
              rules: rules,
              config: config,
              fileResolver: fileResolver,
              reporter: reporter,
            );
          }
        }
      }
    });
  }

  // --- Extension Points (The Agenda) ---

  /// Override to implement logic for Return Types.
  void checkReturn({
    required MethodDeclaration node,
    required DartType type,
    required List<TypeSafetyPolicy> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
  }) {}

  /// Override to implement logic for Parameters.
  void checkParameter({
    required FormalParameter node,
    required DartType type,
    required String paramName,
    required List<TypeSafetyPolicy> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
  }) {}

  // --- Shared Helpers for Subclasses ---

  bool shouldCheckParam(TypeSafetyConstraint c, String paramName) {
    if (c.kind != 'parameter') return false;
    if (c.identifier == null) return true;
    return RegExp(c.identifier!).hasMatch(paramName);
  }
}
