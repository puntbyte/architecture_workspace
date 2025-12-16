// lib/src/lints/consistency/rules/parity_missing_rule.dart

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/actions/architecture_fix.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/consistency/logic/relationship_logic.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ParityMissingRule extends ArchitectureLintRule with NamingLogic, RelationshipLogic {
  static const _code = LintCode(
    name: 'arch_parity_missing',
    problemMessage: 'Missing companion component: "{0}" expected "{1}".',
    correctionMessage: 'Create the missing file to maintain architectural parity.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ParityMissingRule() : super(code: _code);

  @override
  List<Fix> getFixes() => [
    ArchitectureFix(),
  ];

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

    void checkNode(AstNode node, Token nameToken) {
      final result = findMissingTarget(
        node: node,
        config: config,
        currentComponent: component,
        fileResolver: fileResolver,
        currentFilePath: resolver.path,
      );

      // Only report if a target was calculated AND the file is missing
      if (result.target != null) {
        final target = result.target!;
        final file = File(target.path);

        if (!file.existsSync()) {
          reporter.atToken(
            nameToken,
            _code,
            arguments: [
              target.sourceComponent.displayName,
              target.targetClassName,
            ],
          );
        }
      }
    }

    context.registry.addClassDeclaration((node) => checkNode(node, node.name));
    context.registry.addMethodDeclaration((node) => checkNode(node, node.name));
  }
}
