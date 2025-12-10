import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
// Hide LintCode to avoid conflict with custom_lint_builder
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/actions/architecture_fix.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/consistency/logic/relationship_logic.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart'; // Import NamingLogic
import 'package:custom_lint_builder/custom_lint_builder.dart';

// Mixin NamingLogic first, then RelationshipLogic
class ParityMissingRule extends ArchitectureLintRule with NamingLogic, RelationshipLogic {
  static const _debugCode = LintCode(
    name: 'arch_debug_parity',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.INFO,
  );

  const ParityMissingRule() : super(code: _debugCode);

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

    // Optional: Only run on ports for less noise during debug
    // if (!component.id.contains('port')) return;

    void check(AstNode node, Token nameToken) {
      final sb = StringBuffer();
      sb.writeln('[DEBUG PARITY] "${nameToken.lexeme}"');
      sb.writeln('--------------------------------------------------');

      final target = findMissingTarget(
        node: node,
        config: config,
        currentComponent: component,
        fileResolver: fileResolver,
        currentFilePath: resolver.path,
      );

      if (target != null) {
        final file = File(target.path);
        final exists = file.existsSync();

        sb.writeln('✅ Target Calculated:');
        sb.writeln('   • Core Name:   "${target.coreName}"');
        sb.writeln('   • Target Class: "${target.targetClassName}"');
        sb.writeln('   • Target Path:  "${target.path}"');
        sb.writeln('\n📂 File Status: ${exists ? "EXISTS (No Warning)" : "MISSING (Warning)"}');
      } else {
        sb.writeln('❌ No Target Calculated.');
        sb.writeln('   Possible reasons:');
        sb.writeln('   1. No "relationships" rule in architecture.yaml for "${component.id}".');
        sb.writeln('   2. Node name did not match expected pattern for extraction.');
        sb.writeln('   3. Could not find relative path to target component.');
      }

      sb.writeln('--------------------------------------------------');

      // Always report for debugging
      reporter.atToken(
        nameToken,
        _debugCode,
        arguments: [sb.toString()],
      );
    }

    context.registry.addClassDeclaration((node) {
      check(node, node.name);
    });

    context.registry.addMethodDeclaration((node) {
      check(node, node.name);
    });
  }
}