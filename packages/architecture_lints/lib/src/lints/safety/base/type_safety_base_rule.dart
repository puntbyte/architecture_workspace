import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/type_safety_config.dart';
import 'package:architecture_lints/src/config/schema/type_safety_constraint.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/safety/logic/type_safety_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class TypeSafetyBaseRule extends ArchitectureLintRule with TypeSafetyLogic {
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

    // Filter by component context match
    final rules = config.typeSafeties.where((rule) {
      return component.matchesAny(rule.onIds);
    }).toList();

    if (rules.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      // Check Return
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

      // Check Parameters
      final params = node.parameters;
      if (params != null) {
        for (final param in params.parameters) {
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

  void checkReturn({
    required MethodDeclaration node,
    required DartType type,
    required List<TypeSafetyConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
  }) {}

  void checkParameter({
    required FormalParameter node,
    required DartType type,
    required String paramName,
    required List<TypeSafetyConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
  }) {}

  bool shouldCheckParam(TypeSafetyConstraint c, String paramName) {
    if (c.kind != 'parameter') return false;
    if (c.identifier == null) return true;
    return RegExp(c.identifier!).hasMatch(paramName);
  }
}