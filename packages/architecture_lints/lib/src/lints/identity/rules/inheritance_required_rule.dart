import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class InheritanceRequiredRule extends ArchitectureLintRule with InheritanceLogic {
  static const _code = LintCode(
    name: 'arch_type_missing_base',
    problemMessage: 'The component "{0}" must inherit from "{1}".',
    correctionMessage: 'Extend or implement the required type.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  const InheritanceRequiredRule() : super(code: _code);

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
        if (rule.required.isEmpty) continue;

        // Check if ANY supertype matches the requirement
        final hasMatch = supertypes.any(
              (type) => matchesReference(
            type,
            rule.required,
            fileResolver,
            config.typeDefinitions, // <--- Passing the registry
          ),
        );

        if (!hasMatch) {
          report(
            reporter: reporter,
            nodeOrToken: node.name,
            code: _code,
            arguments: [
              component.name ?? component.id,
              // NEW: Pass registry to get nice names
              describeReference(rule.required, config.typeDefinitions),
            ],
          );
        }
      }
    });
  }
}