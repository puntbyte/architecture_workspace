import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/dependency_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/import_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class LayerDependencyRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_dep_layer',
    problemMessage: 'Layer violation: "{0}" cannot import "{1}".',
    correctionMessage: 'Remove the dependency or move the logic to a shared layer.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  const LayerDependencyRule() : super(code: _code);

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

    // 1. Get relevant rules
    final rules = config.dependencies.where((rule) {
      return rule.onIds.any((id) => component.id == id || component.id.startsWith('$id.'));
    }).toList();

    if (rules.isEmpty) return;

    // 2. Check Imports
    context.registry.addImportDirective((node) {
      // Resolve the import to a file path
      final importedPath = ImportResolver.resolvePath(node: node);

      // If importedPath is null, it's likely an external package (dart: or package:other).
      // We ignore those here; ExternalDependencyRule handles them.
      if (importedPath == null) return;

      // Resolve the component of the *imported* file
      final importedComponent = fileResolver.resolve(importedPath);

      if (importedComponent != null) {
        for (final rule in rules) {
          _checkDependency(
            rule,
            component,
            importedComponent,
            node,
            reporter,
          );
        }
      }
    });
  }

  void _checkDependency(
    DependencyConfig rule,
    ComponentConfig current,
    ComponentConfig imported,
    ImportDirective node,
    DiagnosticReporter reporter,
  ) {
    if (current.id == imported.id) return; // Allow self-imports

    // 1. Check Forbidden
    if (_matches(rule.forbidden.components, imported.id)) {
      reporter.atNode(
        node.uri, // Fix: Use atNode for StringLiteral
        _code,
        arguments: [current.name ?? current.id, imported.name ?? imported.id],
      );
      return;
    }

    // 2. Check Allowed (Whitelist)
    // If allowed list is present, the import MUST be in it.
    if (rule.allowed.components.isNotEmpty) {
      if (!_matches(rule.allowed.components, imported.id)) {
        reporter.atNode(
          node.uri, // Fix: Use atNode
          _code,
          arguments: [current.name ?? current.id, imported.name ?? imported.id],
        );
      }
    }
  }

  bool _matches(List<String> list, String id) {
    return list.contains(id) || list.any((item) => id.startsWith('$item.'));
  }
}
