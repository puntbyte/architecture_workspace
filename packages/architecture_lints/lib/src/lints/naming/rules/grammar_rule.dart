import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/engines/language/language_analyzer.dart';
import 'package:architecture_lints/src/lints/naming/base/naming_base_rule.dart';
import 'package:architecture_lints/src/lints/naming/logic/grammar_logic.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class GrammarRule extends NamingBaseRule with GrammarLogic {
  static const _code = LintCode(
    name: 'arch_naming_grammar',
    problemMessage: 'Grammar Violation in {0}: {1}',
    correctionMessage: '{2}',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const GrammarRule() : super(code: _code);

  @override
  void checkName({
    required ClassDeclaration node,
    required ComponentDefinition config,
    required DiagnosticReporter reporter,
    required ArchitectureConfig rootConfig,
  }) {
    // DEBUG: Check what we received
    print('[GrammarRule] Checking "${node.name.lexeme}" against ${config.id}');
    print('[GrammarRule] Config Grammar: ${config.grammar}');

    // 1. Skip if no grammar rules defined
    if (config.grammar.isEmpty) return;

    final className = node.name.lexeme;

    // 2. Initialize Analyzer with User Vocabulary
    final analyzer = LanguageAnalyzer(vocabulary: rootConfig.vocabulary);

    // 3. Check against ALL allowed grammar patterns (OR logic)
    // If the name satisfies ANY of the grammar rules, it is valid.
    var hasMatch = false;
    String? lastReason;
    String? lastCorrection;

    for (final grammar in config.grammar) {
      final result = validateGrammar(grammar, className, analyzer);
      if (result.isValid) {
        hasMatch = true;
        break;
      } else {
        lastReason ??= result.reason;
        lastCorrection ??= result.correction;
      }
    }

    if (!hasMatch && lastReason != null) {
      reporter.atToken(
        node.name,
        _code,
        arguments: [
          config.displayName,
          lastReason,
          lastCorrection ?? 'Check grammar configuration.',
        ],
      );
    }
  }
}
