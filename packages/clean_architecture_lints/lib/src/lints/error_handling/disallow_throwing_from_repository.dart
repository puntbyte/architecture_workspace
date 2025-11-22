// lib/src/lints/error_handling/disallow_throwing_from_repository.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids `throw` expressions inside a repository implementation.
///
/// **Reasoning:** Repositories act as a safety boundary. They are responsible for
/// catching all exceptions from the data layer (DataSources) and converting them
/// into a predictable `Failure` object (usually via `Either`).
///
/// **Note:** This does not flag `rethrow` statements. If you need to catch-log-rethrow,
/// that is technically permitted by this rule, though often discouraged in strict
/// functional error handling.
class DisallowThrowingFromRepository extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_throwing_from_repository',
    problemMessage:
        'Do not throw exceptions from a repository. Return a Failure object in a Left(...) instead.',
    correctionMessage: 'Wrap the operation in a try/catch block and return a Failure.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowThrowingFromRepository({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // 1. Check Component: Only runs on Repository Implementations
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    // 2. Listen for 'throw'
    context.registry.addThrowExpression((node) {
      // This listener triggers on `throw Exception()`.
      // It does NOT trigger on `rethrow;` (which is a RethrowExpression).
      reporter.atNode(node, _code);
    });
  }
}
