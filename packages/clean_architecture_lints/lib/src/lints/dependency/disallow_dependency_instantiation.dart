// lib/src/lints/dependency/disallow_dependency_instantiation.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids classes from creating their own dependencies during instantiation.
///
/// **Reasoning:** In a pure Dependency Injection (DI) architecture, a class must
/// receive its dependencies from an external source (via its constructor), not create
/// them itself. This ensures loose coupling, making classes easy to test with mocks
/// and easy to reuse with different dependency implementations. Flagging direct
/// instantiations in field or constructor initializers enforces this principle.
class DisallowDependencyInstantiation extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_dependency_instantiation',
    problemMessage:
        'Do not instantiate dependencies directly. They should be injected via the constructor.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowDependencyInstantiation({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule applies to concrete implementation classes in the data and presentation layers.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component == ArchComponent.unknown || ArchComponent.domainLayer.contains(component)) {
      return;
    }

    context.registry.addInstanceCreationExpression((node) {
      // We only care about instantiations that happen in two specific places:
      // 1. As the initializer for a field declaration.
      // 2. As the expression in a constructor field initializer.
      final isFieldInitializer = node.thisOrAncestorOfType<FieldDeclaration>() != null;
      final isConstructorInitializer =
          node.thisOrAncestorOfType<ConstructorFieldInitializer>() != null;

      if (!isFieldInitializer && !isConstructorInitializer) {
        return; // The instantiation is happening inside a method body, which is allowed.
      }

      // Get the type being instantiated.
      final type = node.staticType;
      if (type == null) return;

      final source = type.element?.firstFragment.libraryFragment?.source;
      if (source == null) return;

      // The violation occurs if the instantiated type is a "dependency", which we define as
      // any class from another file within our project (`package:` or relative `file:` URI).
      // We ignore SDK types (`dart:`) and dependencies from other packages.
      final isProjectFile =
          source.uri.isScheme('package') &&
              source.uri.path.startsWith('${context.pubspec.name}/') ||
          source.uri.isScheme('file');

      if (isProjectFile && source.fullName != resolver.source.fullName) {
        reporter.atNode(node, _code);
      }
    });
  }
}
