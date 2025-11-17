// lib/src/lints/purity/disallow_flutter_in_domain.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/ast_utils.dart';
import 'package:clean_architecture_lints/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids any dependency on the Flutter SDK within the domain layer.
///
/// **Reasoning:** The domain layer must be pure and platform-independent to ensure
/// business logic is decoupled from the UI framework.
class DisallowFlutterInDomain extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_flutter_in_domain',
    problemMessage: 'Domain layer purity violation: Do not depend on the Flutter SDK.',
    correctionMessage: 'Remove the Flutter dependency and use pure Dart types or domain objects.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowFlutterInDomain({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule applies to any file within the domain layer.
    final component = layerResolver.getComponent(resolver.source.fullName);

    // THE IMPROVEMENT: A clean, single lookup in the static set.
    if (!ArchComponent.domainLayer.contains(component)) return;

    // Check for forbidden import statements.
    context.registry.addImportDirective((node) {
      final importUri = node.uri.stringValue;
      if (importUri != null &&
          (importUri.startsWith('package:flutter/') || importUri == 'dart:ui')) {
        reporter.atNode(node, _code);
      }
    });

    // A generic helper to validate any type annotation using the central utility.
    void validate(TypeAnnotation? typeNode) {
      if (typeNode != null && SemanticUtils.isFlutterType(typeNode.type)) {
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
