// lib/src/lints/structure/disallow_public_members_in_implementation.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that flags public members in an implementation class that do not
/// override a member from a super-interface.
///
/// This enforces encapsulation, ensuring that helper methods or properties are
/// kept private.
class DisallowPublicMembersInImplementation extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_public_members_in_implementation',
    problemMessage: 'Public members in an implementation must override a member from an interface.',
    correctionMessage: 'Make this member private or move it to the interface.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowPublicMembersInImplementation({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataRepository && subLayer != ArchSubLayer.dataSource) return;

    /// A generic helper to check any executable member (method or getter).
    void validate(Declaration memberNode, ExecutableElement? element) {
      if (element == null) return;
      if (element.isPrivate) return;
      if (element is ConstructorElement) return;

      if (!SemanticUtils.isArchitecturalOverride(element, layerResolver)) {
        // THE FIX IS HERE: Use the robust helper to get the token.
        final nameToken = _getNameToken(memberNode);
        if (nameToken != null) {
          reporter.atToken(nameToken, _code);
        }
      }
    }

    // 1. Visit all method declarations.
    context.registry.addMethodDeclaration((node) => validate(node, node.declaredFragment?.element));

    // 2. Visit all field declarations to check their getters.
    context.registry.addFieldDeclaration((node) {
      // We only need to check the first variable in a multi-variable declaration
      // (e.g., `String a, b;`) as the lint applies to the whole declaration.
      final firstVar = node.fields.variables.firstOrNull;
      if (firstVar == null) return;

      final element = firstVar.declaredFragment?.element;
      if (element is PropertyInducingElement) validate(node, element.getter);
    });
  }

  /// A safe helper to get the name Token from different declaration types.
  Token? _getNameToken(Declaration node) {
    if (node is MethodDeclaration) {
      return node.name;
    }
    // For FieldDeclaration, we report on the first variable's name.
    if (node is FieldDeclaration) {
      return node.fields.variables.first.name;
    }
    return null;
  }
}
