// lib/src/lints/purity/disallow_entity_in_data_source.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/ast_utils.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowEntityInDataSource extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_entity_in_data_source',
    problemMessage: 'DataSource purity violation: DataSources should not use domain Entities.',
    correctionMessage:
        'DataSources should return Models/DTOs, not Entities. The repository is responsible for '
        'mapping.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowEntityInDataSource({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataSource) return;

    // A generic helper to check the type of any TypeAnnotation node.
    void validate(TypeAnnotation? typeNode) {
      if (typeNode != null && SemanticUtils.isEntityType(typeNode.type, layerResolver)) {
        reporter.atNode(typeNode, _code);
      }
    }

    // --- Apply the check comprehensively ---

    // 1. Visit all method declarations (return types and parameters).
    context.registry.addMethodDeclaration((node) {
      validate(node.returnType);
      node.parameters?.parameters.forEach(
        (param) => validate(AstUtils.getParameterTypeNode(param)),
      );
    });

    // 2. ADDED: Visit all field declarations.
    context.registry.addFieldDeclaration((node) => validate(node.fields.type));

    // 3. ADDED: Visit all top-level variable declarations.
    context.registry.addTopLevelVariableDeclaration((node) => validate(node.variables.type));

    // 4. ADDED: Visit all local variable declarations.
    context.registry.addVariableDeclarationStatement((node) => validate(node.variables.type));
  }
}
