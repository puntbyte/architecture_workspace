import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/member_config.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/members/logic/member_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class MemberBaseRule extends ArchitectureLintRule with MemberLogic {
  const MemberBaseRule({required super.code});

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

    final rules = config.members.where((rule) {
      return component.matchesAny(rule.onIds);
    }).toList();

    if (rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      checkMembers(
        node: node,
        rules: rules,
        config: config,
        reporter: reporter,
        component: component,
      );
    });
  }

  void checkMembers({
    required ClassDeclaration node,
    required List<MemberConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
    required ComponentContext component,
  });
}