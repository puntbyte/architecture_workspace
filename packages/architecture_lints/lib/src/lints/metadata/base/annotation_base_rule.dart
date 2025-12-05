import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/annotation_config.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/metadata/logic/annotation_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class AnnotationBaseRule extends ArchitectureLintRule with AnnotationLogic {
  const AnnotationBaseRule({required super.code});

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    if (component == null) return;

    final rules = config.annotations.where((rule) {
      return component.matchesAny(rule.onIds);
    }).toList();

    if (rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      checkAnnotations(
        node: node,
        rules: rules,
        config: config,
        reporter: reporter,
        component: component,
      );
    });
  }

  void checkAnnotations({
    required ClassDeclaration node,
    required List<AnnotationConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
    required ComponentContext component,
  });
}
