// lib/src/lints/identity/base/inheritance_base_rule.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/policies/inheritance_policy.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class InheritanceBaseRule extends ArchitectureRule with InheritanceLogic {
  const InheritanceBaseRule({required super.code});

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

    final rules = config.inheritances.where((rule) => component.matchesAny(rule.onIds)).toList();

    if (rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final element = node.declaredFragment?.element;
      if (element == null) return;

      // FIX: Use allSupertypes here too
      final supertypes = element.allSupertypes;

      checkInheritance(
        node: node,
        element: element,
        supertypes: supertypes,
        rules: rules,
        config: config,
        fileResolver: fileResolver,
        reporter: reporter,
        component: component,
      );
    });
  }

  void checkInheritance({
    required ClassDeclaration node,
    required InterfaceElement element,
    required List<InterfaceType> supertypes,
    required List<InheritancePolicy> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
    required ComponentContext component,
  });
}
