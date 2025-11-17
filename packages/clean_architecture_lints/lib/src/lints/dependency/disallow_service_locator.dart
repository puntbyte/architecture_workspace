// lib/src/lints/dependency/disallow_service_locator.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids the use of the Service Locator pattern (e.g., `getIt<T>()`)
/// within architectural layers.
///
/// **Reasoning:** Dependencies should be explicit and injected via constructors.
/// Using a global service locator hides dependencies, making code harder to test,
/// understand, and refactor. It couples the class to the locator framework.
class DisallowServiceLocator extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_service_locator',
    problemMessage:
        'Do not use a service locator. Dependencies should be explicit and injected via the '
        'constructor.',
    correctionMessage: 'Add this dependency as a constructor parameter.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowServiceLocator({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // We want to enforce this in all known architectural components.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component == ArchComponent.unknown) return;

    // Access the configured locator names (e.g., ['getIt', 'sl', 'locator']).
    final locatorNames = config.services.dependencyInjection.serviceLocatorNames.toSet();
    if (locatorNames.isEmpty) return;

    // Helper to check and report.
    void checkName(String name, AstNode node) {
      if (locatorNames.contains(name)) {
        reporter.atNode(node, _code);
      }
    }

    // 1. Check Method Invocations (e.g., `getIt<Type>()` or `getIt()`)
    context.registry.addMethodInvocation((node) {
      if (node.target == null && locatorNames.contains(node.methodName.name)) {
        reporter.atNode(node, _code);
      }
    });

    // 2. Check Property/Identifier Access (e.g., `final x = getIt;` or `getIt.call<T>()`)
    context.registry.addSimpleIdentifier((node) {
      // Skip if it's the method name in an invocation (handled above) or a declaration.
      if (node.parent is MethodInvocation) {
        final methodInvocation = node.parent as MethodInvocation?;
        if (methodInvocation?.methodName == node) return;
      }

      if (node.inDeclarationContext()) return;

      checkName(node.name, node);
    });
  }
}
