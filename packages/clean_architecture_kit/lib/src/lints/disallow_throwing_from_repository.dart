// lib/src/lints/disallow_throwing_from_repository.dart
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowThrowingFromRepository extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_throwing_from_repository',
    problemMessage: 'Do not throw exceptions from a repository. Return a Failure object instead.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowThrowingFromRepository({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataRepository) return;

    context.registry.addThrowExpression((node) {
      // Flag every `throw` expression within a data repository.
      reporter.atNode(node, _code);
    });
  }
}
