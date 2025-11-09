// lib/src/lints/dependency_injection/disallow_dependency_instantiation.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowDependencyInstantiation extends CleanArchitectureLintRule  {
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
    final currentLayer = layerResolver.getLayer(resolver.source.fullName);
    if (currentLayer == ArchLayer.unknown || currentLayer == ArchLayer.domain) return;

    context.registry.addInstanceCreationExpression((node) {
      // Check if this instantiation happens inside a constructor's initializer list or a field
      // declaration.
      final isInitializer = node.thisOrAncestorOfType<ConstructorFieldInitializer>() != null;
      final isField = node.thisOrAncestorOfType<FieldDeclaration>() != null;

      if (isInitializer || isField) {
        final type = node.staticType;
        if (type == null) return;

        final source = type.element?.firstFragment.libraryFragment?.source;
        if (source == null) return;

        // A dependency is any class from another file that isn't from dart:core, etc.
        if (source.uri.isScheme('package') || source.uri.isScheme('file')) {
          if (source.fullName != resolver.source.fullName) {
            reporter.atNode(node, _code);
          }
        }
      }
    });
  }
}
