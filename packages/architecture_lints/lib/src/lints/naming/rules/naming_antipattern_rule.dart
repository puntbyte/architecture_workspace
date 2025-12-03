// lib/src/lints/naming/rules/naming_antipattern_rule.dart

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NamingAntipatternRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_naming_antipattern',
    problemMessage: 'The name "{0}" matches a forbidden pattern for this component.',
    correctionMessage: 'Rename the class to avoid the pattern "{1}".',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const NamingAntipatternRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    ComponentConfig? component,
    FileResolver? fileResolver,
  }) {
    // 1. If the file doesn't belong to a component, ignore it.
    if (component == null) return;

    // 2. If the component has no antipatterns defined, ignore it.
    if (component.antipatterns.isEmpty) return;

    // 3. Visit the AST
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;

      // 4. Check against all forbidden patterns
      for (final antipattern in component.antipatterns) {
        // If it returns TRUE, it means the class name MATCHES the forbidden pattern.
        // This is a violation.
        if (NamingUtils.validateName(name: className, template: antipattern)) {
          reporter.atToken(node.name, _code, arguments: [className, antipattern]);

          // Stop after finding the first violation to avoid spamming multiple warnings
          // for the same class if it matches multiple antipatterns.
          break;
        }
      }
    });
  }
}
