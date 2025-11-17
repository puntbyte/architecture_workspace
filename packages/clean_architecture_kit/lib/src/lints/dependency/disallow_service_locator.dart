// lib/src/lints/dependency_injection/disallow_service_locator.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowServiceLocator extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_service_locator',
    problemMessage:
        'Do not use a service locator. Dependencies should be explicit and injected via the '
        'constructor.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowServiceLocator({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final layer = layerResolver.getLayer(resolver.source.fullName);
    if (layer == ArchLayer.unknown) return;

    final locatorNames = config.services.dependencyInjection.serviceLocatorNames.toSet();
    if (locatorNames.isEmpty) return;

    context.registry.addMethodInvocation((node) {
      // Is it a top-level function call? (e.g., getIt<...>() )
      if (node.target == null && locatorNames.contains(node.methodName.name)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
