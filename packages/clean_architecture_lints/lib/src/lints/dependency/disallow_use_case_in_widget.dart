// lib/src/lints/dependency/disallow_use_case_in_widget.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/ast_utils.dart';
import 'package:clean_architecture_lints/src/utils/semantic_utils.dart';

import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids any reference to or invocation of a UseCase within a widget file.
///
/// **Reasoning:** Widgets are for presentation (UI) only. They should be "dumb" and
/// receive their state from a dedicated state management class (a "manager" like a
/// BLoC, Cubit, or Provider). Business logic, which is encapsulated in UseCases,
/// must be called from within those managers, never directly from a widget. This
/// ensures a clean separation of concerns and makes both UI and logic easier to test.
class DisallowUseCaseInWidget extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_use_case_in_widget',
    problemMessage: 'Widgets must not depend on or invoke UseCases directly.',
    correctionMessage: 'Move this dependency or call to a presentation manager (e.g., a BLoC or Cubit).',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowUseCaseInWidget({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule only applies to files within a 'widget' directory.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.widget) return;

    /// A generic helper that checks if a type is a UseCase and reports an error.
    void validate({
      required SyntacticEntity reportNode,
      required DartType? type,
    }) {
      if (SemanticUtils.isComponent(type, layerResolver, ArchComponent.usecase)) {
        reporter.atEntity(reportNode, _code);
      }
    }

    // --- Apply the check comprehensively ---

    // 1. Visit fields.
    context.registry.addFieldDeclaration((node) {
      for (final variable in node.fields.variables) {
        validate(
          reportNode: node.fields.type ?? variable.name,
          type: variable.declaredFragment?.element.type,
        );
      }
    });

    // 2. Visit constructor parameters.
    context.registry.addConstructorDeclaration((node) {
      for (final parameter in node.parameters.parameters) {
        validate(
          reportNode: parameter,
          type: parameter.declaredFragment?.element.type,
        );
      }
    });

    // 3. Visit method signatures.
    context.registry.addMethodDeclaration((node) {
      final returnTypeNode = node.returnType;
      if (returnTypeNode != null) {
        validate(reportNode: returnTypeNode, type: returnTypeNode.type);
      }
      for (final parameter in node.parameters?.parameters ?? <FormalParameter>[]) {
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        if (typeNode != null) {
          validate(reportNode: typeNode, type: typeNode.type);
        }
      }
    });

    // 4. Visit local variables.
    context.registry.addVariableDeclarationStatement((node) {
      for (final variable in node.variables.variables) {
        validate(
          reportNode: node.variables.type ?? variable.name,
          type: variable.declaredFragment?.element.type,
        );
      }
    });

    // 5. Visit top-level variables.
    context.registry.addTopLevelVariableDeclaration((node) {
      for (final variable in node.variables.variables) {
        validate(
          reportNode: node.variables.type ?? variable.name,
          type: variable.declaredFragment?.element.type,
        );
      }
    });

    // 6. Visit method invocations to catch direct calls like `_useCase.call()`.
    context.registry.addMethodInvocation((node) {
      validate(reportNode: node, type: node.target?.staticType);
    });
  }
}
