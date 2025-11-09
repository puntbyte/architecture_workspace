// lib/src/lints/purity/disallow_model_in_domain.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/utils/ast_utils.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that disallows the use of data-layer Models in domain-layer signatures.
///
/// This is the core purity rule for the domain layer, ensuring it only deals with pure domain
/// Entities by checking the definition location of types used.
class DisallowModelInDomain extends CleanArchitectureLintRule {
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
    final layer = layerResolver.getLayer(resolver.source.fullName);
    if (layer != ArchLayer.domain) return;

    void validate(TypeAnnotation? typeNode) {
      if (typeNode != null && SemanticUtils.isModelType(typeNode.type, layerResolver)) {
        reporter.atNode(typeNode, _code);
      }
    }

    // Visit all method declarations.
    context.registry.addMethodDeclaration((node) {
      validate(node.returnType);
      node.parameters?.parameters.forEach(
        (param) => validate(AstUtils.getParameterTypeNode(param)),
      );
    });

    // Visit all field declarations.
    context.registry.addFieldDeclaration((node) => validate(node.fields.type));

    // Visit top-level variables.
    context.registry.addTopLevelVariableDeclaration((node) => validate(node.variables.type));

    // Visit local variables.
    context.registry.addVariableDeclarationStatement((node) => validate(node.variables.type));
  }
}
