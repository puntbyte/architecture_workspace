import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/consistency/fixes/create_missing_component_fix.dart';
import 'package:architecture_lints/src/lints/consistency/logic/relationship_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ParityMissingRule extends ArchitectureLintRule with RelationshipLogic {
  static const _code = LintCode(
    name: 'arch_parity_missing',
    problemMessage: 'Missing companion component: "{0}" expected "{1}".',
    correctionMessage: 'Create the missing file to maintain architectural parity.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ParityMissingRule() : super(code: _code);

  @override
  List<Fix> getFixes() => [
    CreateMissingComponentFix(),
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

    context.registry.addClassDeclaration((node) {
      _checkNode(node, config, component, resolver.path, fileResolver, reporter);
    });

    context.registry.addMethodDeclaration((node) {
      _checkNode(node, config, component, resolver.path, fileResolver, reporter);
    });
  }

  void _checkNode(
      AstNode node,
      ArchitectureConfig config,
      ComponentContext component,
      String currentFilePath,
      FileResolver fileResolver,
      DiagnosticReporter reporter,
      ) {
    final target = findMissingTarget(
      node: node,
      config: config,
      currentComponent: component,
      fileResolver: fileResolver,
      currentFilePath: currentFilePath,
    );

    if (target != null) {
      final file = File(target.path);
      if (!file.existsSync()) {

        Token? nameToken;
        if (node is ClassDeclaration) {
          nameToken = node.name;
        } else if (node is MethodDeclaration) {
          nameToken = node.name;
        }

        if (nameToken != null) {
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
  }
}