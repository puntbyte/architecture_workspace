// lib/src/lints/purity/disallow_entity_in_data_source.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/ast_utils.dart';
import 'package:clean_architecture_lints/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids any reference to a domain `Entity` within a `DataSource`.
///
/// **Reasoning:** The data layer's responsibility is to deal with raw data and
/// data transfer objects (Models). It must not know about the pure business
/// objects of the domain layer (Entities).
class DisallowEntityInDataSource extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_entity_in_data_source',
    problemMessage: 'DataSources must not depend on or reference domain Entities.',
    correctionMessage: 'Use a data Model (DTO) instead. The repository is responsible for mapping.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowEntityInDataSource({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule applies to both the interface and implementation of a DataSource.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.sourceInterface && component != ArchComponent.sourceImplementation) {
      return;
    }

    // A generic helper to validate any type annotation.
    void validate(TypeAnnotation? typeNode) {
      // The logic is now a clean, single call to the semantic utility.
      if (typeNode != null &&
          SemanticUtils.isComponent(typeNode.type, layerResolver, ArchComponent.entity)) {
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
