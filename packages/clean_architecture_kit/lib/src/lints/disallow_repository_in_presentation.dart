// lib/src/lints/disallow_repository_in_presentation.dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/utils/ast_utils.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowRepositoryInPresentation extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_repository_in_presentation',
    problemMessage: 'Presentation layer purity violation: Do not depend directly on a Repository.',
    correctionMessage:
        'The presentation layer should depend on a specific UseCase, not the entire repository.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowRepositoryInPresentation({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final layer = layerResolver.getLayer(resolver.source.fullName);
    if (layer != ArchLayer.presentation) return;

    /// A generic helper that checks the type and reports an error on the correct node.
    void checkNodeAndReport({
      required SyntacticEntity reportNode,
      required DartType? type,
    }) {
      if (SemanticUtils.isRepositoryInterfaceType(type, config.naming)) {
        reporter.atEntity(reportNode, _code);
      }
    }

    // Visit fields.
    context.registry.addFieldDeclaration((node) {
      for (final variable in node.fields.variables) {
        checkNodeAndReport(
          reportNode: node.fields.type ?? variable.name,
          type: variable.declaredFragment?.element.type,
        );
      }
    });

    // 2. Visit constructor parameters.
    context.registry.addConstructorDeclaration((node) {
      for (final parameter in node.parameters.parameters) {
        checkNodeAndReport(
          reportNode: parameter,
          type: parameter.declaredFragment?.element.type,
        );
      }
    });

    // 3. Visit method signatures.
    context.registry.addMethodDeclaration((node) {
      // Check return type
      if (node.returnType != null) {
        checkNodeAndReport(
          reportNode: node.returnType!,
          type: node.returnType!.type,
        );
      }
      // Check parameters
      for (final parameter in node.parameters?.parameters ?? <FormalParameter>[]) {
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        if (typeNode != null) {
          checkNodeAndReport(
            reportNode: typeNode,
            type: typeNode.type,
          );
        }
      }
    });

    // 4. Visit local variables.
    context.registry.addVariableDeclarationStatement((node) {
      for (final variable in node.variables.variables) {
        checkNodeAndReport(
          reportNode: node.variables.type ?? variable.name,
          type: variable.declaredFragment?.element.type,
        );
      }
    });

    // 5. Visit top-level variables.
    context.registry.addTopLevelVariableDeclaration((node) {
      for (final variable in node.variables.variables) {
        checkNodeAndReport(
          reportNode: node.variables.type ?? variable.name,
          type: variable.declaredFragment?.element.type,
        );
      }
    });
  }
}
