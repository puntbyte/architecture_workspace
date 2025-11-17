// lib/src/lints/error_handling/enforce_try_catch_in_repository.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that ensures calls to a DataSource within a repository are wrapped in a try-catch block.
///
/// **Reasoning:** Since DataSources are expected to throw exceptions on failure, the repository
/// (as the safety boundary) MUST anticipate and handle these exceptions. This lint enforces
/// that any method invocation on a `DataSource` object occurs inside a `TryStatement`.
class EnforceTryCatchInRepository extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_try_catch_in_repository',
    problemMessage:
        'Calls to a DataSource must be wrapped in a try-catch block to handle potential '
        'exceptions.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceTryCatchInRepository({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule only applies to repository implementations.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    context.registry.addMethodInvocation((node) {
      final targetType = node.target?.staticType;
      if (targetType == null) return;

      final source = targetType.element?.firstFragment.libraryFragment?.source;
      if (source == null) return;

      // Is the target of the method call a DataSource?
      final targetComponent = layerResolver.getComponent(source.fullName);
      if (targetComponent == ArchComponent.source ||
          targetComponent == ArchComponent.sourceImplementation) {
        // If it is a DataSource call, check if it's inside a `TryStatement`.
        if (node.thisOrAncestorOfType<TryStatement>() == null) {
          reporter.atNode(node, _code);
        }
      }
    });
  }
}
