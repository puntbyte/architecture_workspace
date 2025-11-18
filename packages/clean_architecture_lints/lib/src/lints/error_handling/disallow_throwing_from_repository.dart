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
/// into a predictable `Failure` object within a `Left` side of an `Either`.
/// Throwing an exception from a repository breaks this contract and leaks
/// data-layer concerns into the domain or presentation layers.
class DisallowThrowingFromRepository extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_throwing_from_repository',
    problemMessage:
        'Do not throw exceptions from a repository. Return a Failure object in a Left(...) '
        'instead.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowThrowingFromRepository({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule only applies to files identified as repository implementations.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    context.registry.addThrowExpression((node) {
      // Flag every `throw` expression found within a repository implementation file.
      reporter.atNode(node, _code);
    });
  }
}
