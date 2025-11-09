// lib/src/lints/purity/disallow_use_case_in_widget.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/ast_utils.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that flags any reference to a UseCase type within a widget file.
///
/// This enforces the principle that business logic dependencies should not exist in the UI layer.
/// It checks fields, constructors, and method signatures.
class DisallowUseCaseInWidget extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_use_case_in_widget',
    problemMessage: 'Widgets should not depend on or reference UseCases directly.',
    correctionMessage:
        'Remove the UseCase dependency. Instead, call the UseCase from a presentation manager '
            '(Bloc, Cubit, etc.) and expose state to the widget.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowUseCaseInWidget({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.widget) return;

    /// A generic helper that checks the type and reports an error on the correct node.
    void validate(SyntacticEntity node, DartType? type) {
      if (SemanticUtils.isUseCaseType(type, config.naming)) reporter.atEntity(node, _code);
    }

    // Visit fields.
    context.registry.addFieldDeclaration((node) {
      for (final variable in node.fields.variables) {
        validate(node.fields.type ?? variable.name, variable.declaredFragment?.element.type);
      }
    });

    // Visit constructor parameters.
    context.registry.addConstructorDeclaration((node) {
      for (final parameter in node.parameters.parameters) {
        validate(parameter, parameter.declaredFragment?.element.type);
      }
    });


    // Visit method signatures.
    context.registry.addMethodDeclaration((node) {
      if (node.returnType != null) validate(node.returnType!, node.returnType!.type);

      for (final parameter in node.parameters?.parameters ?? <FormalParameter>[]) {
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        if (typeNode != null) validate(typeNode, typeNode.type);
      }
    });

    // Visit local variables.
    context.registry.addVariableDeclarationStatement((node) {
      for (final variable in node.variables.variables) {
        validate(node.variables.type ?? variable.name, variable.declaredFragment?.element.type);
      }
    });

    // Visit top-level variables.
    context.registry.addTopLevelVariableDeclaration((node) {
      for (final variable in node.variables.variables) {
        validate(node.variables.type ?? variable.name, variable.declaredFragment?.element.type);
      }
    });

    // Visit method invocations as a final check.
    context.registry.addMethodInvocation((node) => validate(node, node.target?.staticType));
  }
}
