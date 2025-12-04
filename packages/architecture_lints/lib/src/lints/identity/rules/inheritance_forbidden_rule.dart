import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class InheritanceForbiddenRule extends ArchitectureLintRule with InheritanceLogic {
  static const _code = LintCode(
    name: 'arch_type_forbidden',
    problemMessage: 'The component "{0}" must not inherit from "{1}".',
    correctionMessage: 'Remove the forbidden inheritance.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  const InheritanceForbiddenRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentConfig? component,
  }) {
    if (component == null) return;

    final rules = config.inheritances.where((rule) {
      return rule.onIds.any((id) => componentMatches(id, component.id));
    }).toList();

    if (rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final element = node.declaredFragment?.element;
      if (element == null) return;

      final supertypes = getImmediateSupertypes(element);

      for (final rule in rules) {
        if (rule.forbidden.isEmpty) continue;

        for (final type in supertypes) {
          if (matchesReference(
            type,
            rule.forbidden,
            fileResolver,
            config.typeDefinitions, // <--- Passing the registry
          )) {
            report(
              reporter: reporter,
              nodeOrToken: getNodeForType(node, type) ?? node.name,
              code: _code,
              arguments: [
                component.name ?? component.id,
                type.element.name ?? 'Unknown',
              ],
            );
          }
        }
      }
    });
  }
}