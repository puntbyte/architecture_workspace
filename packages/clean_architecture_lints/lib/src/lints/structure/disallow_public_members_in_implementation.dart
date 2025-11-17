// lib/srcs/lints/structure/disallow_public_members_in_implementation.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that flags public members in an implementation class that do not
/// override a member from a super-interface.
///
/// **Reasoning:** This enforces encapsulation. The public API of a concrete
/// implementation (like a Repository or DataSource) should be defined exclusively
/// by its abstract contract. Any other public members represent a "leaky abstraction"
/// and a violation of the Single Responsibility Principle. Helper methods should be private.
class DisallowPublicMembersInImplementation extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_public_members_in_implementation',
    problemMessage: 'Public members in an implementation must override a member from an interface.',
    correctionMessage:
        'Make this member private (prefix with `_`) or add it to the interface contract.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowPublicMembersInImplementation({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  /// A safe helper to get the name Token from different declaration types.
  Token? _getNameToken(Declaration node) {
    if (node is MethodDeclaration) return node.name;
    if (node is FieldDeclaration) return node.fields.variables.first.name;
    return null;
  }

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule applies to concrete implementations in the data layer.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository && component != ArchComponent.sourceImplementation) {
      return;
    }

    /// A generic helper to validate any executable member (method or getter).
    void validate(Declaration memberNode, ExecutableElement? element) {
      if (element == null) return;

      // We only care about public members.
      if (element.isPrivate) return;

      // Constructors are a special case and must be public for instantiation.
      if (element is ConstructorElement) return;

      // Use the robust, centralized utility to check if it's an architectural override.
      if (!SemanticUtils.isArchitecturalOverride(element, layerResolver)) {
        final nameToken = _getNameToken(memberNode);
        if (nameToken != null) {
          reporter.atToken(nameToken, _code);
        }
      }
    }

    // 1. Visit all method declarations.
    context.registry.addMethodDeclaration((node) {
      validate(node, node.declaredFragment?.element);
    });

    // 2. Visit all field declarations to check their implicit getters.
    context.registry.addFieldDeclaration((node) {
      final firstVar = node.fields.variables.firstOrNull;
      if (firstVar == null) return;

      final element = firstVar.declaredFragment?.element;
      if (element is PropertyInducingElement) {
        // It's the getter that actually overrides the interface contract.
        validate(node, element.getter);
      }
    });
  }
}
