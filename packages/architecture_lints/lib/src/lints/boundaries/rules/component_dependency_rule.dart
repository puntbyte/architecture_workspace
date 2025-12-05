import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/import_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ComponentDependencyRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_dep_component',
    problemMessage: 'Dependency Violation: {0} cannot depend on {1}.{2}',
    correctionMessage: 'Remove the dependency to maintain architectural boundaries.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ComponentDependencyRule() : super(code: _code);

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

    // 1. Find all rules that apply to this component
    final rules = config.dependencies.where((rule) {
      return component.matchesAny(rule.onIds);
    }).toList();

    if (rules.isEmpty) return;

    // 2. Aggregate Constraints (Union Logic)
    final allForbidden = <String>{};
    final allAllowed = <String>{};
    var hasWhitelist = false;

    for (final rule in rules) {
      // Collect forbidden
      allForbidden.addAll(rule.forbidden.components);

      // Collect allowed
      // We only consider it a "whitelist rule" if it actually defines allowed items.
      // Rules that only define 'forbidden' are considered "Permissive" (Allow All except X).
      if (rule.allowed.components.isNotEmpty) {
        hasWhitelist = true;
        allAllowed.addAll(rule.allowed.components);
      }
    }

    // Helper to validate a specific dependency target
    void checkViolation({
      required ComponentContext targetComponent,
      required Object nodeOrToken,
    }) {
      if (component.id == targetComponent.id) return;

      // Calculate Suggestion String based on allAllowed
      // allAllowed is calculated in runWithConfig (see previous implementation)
      var suggestion = '';
      if (allAllowed.isNotEmpty) {
        // Humanize the allowed list
        // We limit to 3 items to keep message short
        final allowedDisplay = allAllowed
            .take(3)
            .map((id) {
              // Basic capitalization for display
              return id.split('.').map((s) => s[0].toUpperCase() + s.substring(1)).join(' ');
            })
            .join(', ');

        suggestion = ' Allowed dependencies: $allowedDisplay${allAllowed.length > 3 ? '...' : ''}.';
      }

      // A. Check Forbidden
      if (targetComponent.matchesAny(allForbidden.toList())) {
        _report(
          reporter: reporter,
          nodeOrToken: nodeOrToken,
          current: component,
          target: targetComponent,
          suggestion: suggestion, // Pass it
        );
        return;
      }

      // B. Check Allowed
      if (hasWhitelist) {
        if (!targetComponent.matchesAny(allAllowed.toList())) {
          _report(
            reporter: reporter,
            nodeOrToken: nodeOrToken,
            current: component,
            target: targetComponent,
            suggestion: suggestion, // Pass it
          );
        }
      }
    }

    // 3. Check Imports
    context.registry.addImportDirective((node) {
      final importedPath = ImportResolver.resolvePath(node: node);
      if (importedPath == null) return;

      final targetComponent = fileResolver.resolve(importedPath);
      if (targetComponent != null) {
        checkViolation(targetComponent: targetComponent, nodeOrToken: node.uri);
      }
    });

    // 4. Check Usages
    context.registry.addNamedType((node) {
      final element = node.element;
      if (element == null) return;

      final library = element.library;
      if (library == null || library.isInSdk || library.isDartCore) return;

      final sourcePath = library.firstFragment.source.fullName;
      final targetComponent = fileResolver.resolve(sourcePath);

      if (targetComponent != null) {
        checkViolation(targetComponent: targetComponent, nodeOrToken: node);
      }
    });
  }

  void _report({
    required DiagnosticReporter reporter,
    required Object nodeOrToken,
    required ComponentContext current,
    required ComponentContext target,
    required String suggestion,
  }) {
    final args = [
      current.displayName,
      target.displayName,
      suggestion,
    ];

    if (nodeOrToken is AstNode) {
      reporter.atNode(nodeOrToken, _code, arguments: args);
    } else if (nodeOrToken is Token) {
      reporter.atToken(nodeOrToken, _code, arguments: args);
    }
  }
}
