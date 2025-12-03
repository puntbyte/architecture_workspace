// lib/src/lints/naming/rules/naming_pattern_rule.dart

import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NamingPatternRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_naming_pattern',
    problemMessage: 'Class name does not match the architectural pattern "{0}".',
    correctionMessage: 'Rename the class to match the required pattern (e.g., {{pattern}}).',
  );

  const NamingPatternRule() : super(code: _code);

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

    // 2. If the component has no naming patterns defined, ignore it.
    if (component.patterns.isEmpty) return;

    // 3. Visit the AST to find Class Declarations
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;

      // 4. Check against all allowed patterns
      var hasAnyMatch = false;
      for (final pattern in component.patterns) {
        if (NamingUtils.validateName(name: className, template: pattern)) {
          hasAnyMatch = true;
          break;
        }
      }

      // 5. Report if no match found
      if (!hasAnyMatch) {
        // Report error listing all allowed patterns joined by " or "
        final allowedPatterns = component.patterns.join(' or ');

        reporter.atToken(node.name, _code, arguments: [allowedPatterns]);
      }
    });
  }
}
