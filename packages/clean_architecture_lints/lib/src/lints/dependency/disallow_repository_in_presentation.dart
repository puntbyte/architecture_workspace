// lib/src/lints/dependency/disallow_repository_in_presentation.dart

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

/// A lint that forbids any reference to a Repository within the presentation layer.
///
/// **Reasoning:** The presentation layer (Widgets, Blocs, etc.) should not be
/// coupled to the data layer. Its only dependency should be on the domain layer,

/// specifically through `UseCases`. A UseCase provides a narrow, specific contract
/// for a single piece of business logic, whereas a Repository is a broad contract
/// for a data source. Depending on a repository tempts the presentation layer to
/// perform business logic that belongs in a UseCase.
class DisallowRepositoryInPresentation extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_repository_in_presentation',
    problemMessage: 'Presentation layer purity violation: Do not depend directly on a Repository.',
    correctionMessage: 'Depend on a specific UseCase instead, and inject it via the constructor.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowRepositoryInPresentation({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule applies to any file within the presentation layer.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (!ArchComponent.presentationLayer.contains(component)) return;

    /// A generic helper that checks the type and reports an error on the correct node.
    void validate({
      required SyntacticEntity reportNode,
      required DartType? type,
    }) {
      // The core logic: check if the type is a repository contract.
      if (SemanticUtils.isComponent(type, layerResolver, ArchComponent.port)) {
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
      // Check return type
      final returnTypeNode = node.returnType;
      if (returnTypeNode != null) {
        validate(reportNode: returnTypeNode, type: returnTypeNode.type);
      }
      // Check parameters
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
  }
}
