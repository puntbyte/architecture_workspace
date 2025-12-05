import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MisplacedComponentRule extends ArchitectureLintRule with NamingLogic {
  static const _code = LintCode(
    name: 'arch_location',
    problemMessage: 'The class "{0}" appears to be a {1}, but it is located in the wrong layer.',
    correctionMessage: 'Move this file to the "{2}" directory.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const MisplacedComponentRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;

      // 1. Quick Exit: If it matches current component, valid.
      if (component != null && component.patterns.isNotEmpty) {
        for (final pattern in component.patterns) {
          if (validateName(className, pattern)) return;
        }
      }

      // 2. Scan other components
      ComponentConfig? bestMatch;
      int bestMatchSpecificity = -1;

      for (final otherComponent in config.components) {
        if (component != null && otherComponent.id == component.id) continue;
        if (otherComponent.paths.isEmpty || otherComponent.patterns.isEmpty) continue;

        for (final pattern in otherComponent.patterns) {
          if (validateName(className, pattern)) {
            if (pattern.length > bestMatchSpecificity) {
              bestMatchSpecificity = pattern.length;
              bestMatch = otherComponent;
            }
          }
        }
      }

      if (bestMatch != null) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [
            className,
            bestMatch.displayName,
            bestMatch.paths.join('" or "'),
          ],
        );
      }
    });
  }
}