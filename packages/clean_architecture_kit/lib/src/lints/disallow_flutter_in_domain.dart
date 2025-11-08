// lib/src/lints/disallow_flutter_in_domain.dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/utils/ast_utils.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that flags any usage of a type from the Flutter SDK within the
/// domain layer. This checks fields, method return types, and parameters.
class DisallowFlutterInDomain extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_flutter_in_domain',
    problemMessage: 'Domain layer purity violation: Do not depend on Flutter.',
    correctionMessage:
        'The domain layer must be platform-independent. Remove the Flutter import and replace any '
        'Flutter types with pure Dart types or domain-specific entities.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowFlutterInDomain({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final layer = layerResolver.getLayer(resolver.source.fullName);
    if (layer != ArchLayer.domain) return;

    // This provides a high-level warning on the import itself.
    context.registry.addImportDirective((node) {
      final importUri = node.uri.stringValue;
      if (importUri != null) {
        // We check for both package:flutter and dart:ui here for completeness.
        if (importUri.startsWith('package:flutter/') || importUri == 'dart:ui') {
          reporter.atNode(node, _code);
        }
      }
    });

    // A helper to pass to the visitors.
    void validate(TypeAnnotation? typeNode) {
      if (typeNode != null && SemanticUtils.isFlutterType(typeNode.type)) {
        reporter.atNode(typeNode, _code);
      }
    }

    // Visit all method declarations to check return types and parameters.
    context.registry.addMethodDeclaration((node) {
      validate(node.returnType);
      node.parameters?.parameters.forEach(
        (param) => validate(AstUtils.getParameterTypeNode(param)),
      );
    });

    // Visit all field declarations.
    context.registry.addFieldDeclaration((node) => validate(node.fields.type));

    // Visit all top-level variable declarations.
    context.registry.addTopLevelVariableDeclaration((node) => validate(node.variables.type));
  }
}
