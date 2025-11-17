// lib/src/lints/purity/disallow_model_in_domain.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/ast_utils.dart';
import 'package:clean_architecture_lints/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids any reference to a data-layer `Model` within the domain layer.
///
/// **Reasoning:** The domain layer must not know about the implementation details of the
/// data layer. Data-layer Models (DTOs) are a data transfer detail. The domain layer
/// should only ever deal with its own pure `Entity` objects.
class DisallowModelInDomain extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_model_in_domain',
    problemMessage: 'Domain layer purity violation: Do not use a data-layer Model.',
    correctionMessage: 'Replace this Model with a pure domain Entity.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowModelInDomain({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule applies to any file within the domain layer.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (!ArchComponent.domainLayer.contains(component)) return;

    void validate(TypeAnnotation? typeNode) {
      if (typeNode != null &&
          SemanticUtils.isComponent(typeNode.type, layerResolver, ArchComponent.model)) {
        reporter.atNode(typeNode, _code);
      }
    }

    // Apply the check comprehensively.
    context.registry.addMethodDeclaration((node) {
      validate(node.returnType);
      node.parameters?.parameters.forEach(
        (param) => validate(AstUtils.getParameterTypeNode(param)),
      );
    });
    context.registry.addFieldDeclaration((node) => validate(node.fields.type));
    context.registry.addTopLevelVariableDeclaration((node) => validate(node.variables.type));
    context.registry.addVariableDeclarationStatement((node) => validate(node.variables.type));
  }
}
