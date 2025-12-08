// lib/src/lints/safety/base/exception_base_rule.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/exception_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/safety/logic/exception_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class ExceptionBaseRule extends ArchitectureLintRule with ExceptionLogic {
  const ExceptionBaseRule({required super.code});

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

    final rules = config.exceptions.where((rule) {
      return component.matchesAny(rule.onIds);
    }).toList();

    if (rules.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      if (node.body is EmptyFunctionBody) return;
      checkMethod(node: node, rules: rules, config: config, reporter: reporter);
    });

    context.registry.addCatchClause((node) {
      checkCatch(node: node, rules: rules, config: config, reporter: reporter);
    });
  }

  void checkMethod({
    required MethodDeclaration node,
    required List<ExceptionConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
  }) {}

  void checkCatch({
    required CatchClause node,
    required List<ExceptionConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
  }) {}
}