import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/import_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class LayerDependencyRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_dep_layer',
    problemMessage: 'Layer violation: "{0}" cannot depend on "{1}".',
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

    // 1. Get relevant rules for this component
    final rules = config.dependencies.where((rule) {
      return rule.onIds.any((id) => component.id == id || component.id.startsWith('$id.'));
    }).toList();

    if (rules.isEmpty) return;

    // 2. Helper to check specific violation logic
    void checkViolation({
      required ComponentConfig importedComponent,
      required AstNode node,
    }) {
      if (component.id == importedComponent.id) return; // Self-reference allowed

      for (final rule in rules) {
        // A. Check Forbidden
        if (_matches(rule.forbidden.components, importedComponent.id)) {
          reporter.atNode(
            node,
            _code,
            arguments: [component.name ?? component.id, importedComponent.name ?? importedComponent.id],
          );
          return;
        }

        // B. Check Allowed (Whitelist)
        if (rule.allowed.components.isNotEmpty) {
          if (!_matches(rule.allowed.components, importedComponent.id)) {
            reporter.atNode(
              node,
              _code,
              arguments: [component.name ?? component.id, importedComponent.name ?? importedComponent.id],
            );
          }
        }
      }
    }

    // 3. Listener A: Check Imports (The Firewall)
    context.registry.addImportDirective((node) {
      final importedPath = ImportResolver.resolvePath(node: node);
      if (importedPath == null) return;

      final importedComponent = fileResolver.resolve(importedPath);
      if (importedComponent != null) {
        checkViolation(importedComponent: importedComponent, node: node.uri);
      }
    });

    // 4. Listener B: Check Usages (The Leaks)
    // This catches specific types used in fields, methods, extends, etc.
    context.registry.addNamedType((node) {
      final element = node.element;
      if (element == null) return;

      // We only care if the element comes from a different library
      final library = element.library;
      if (library == null || library.isDartCore || library.isInSdk) return;

      // Resolve the source file of the element being used
      // Note: library.source.fullName might be abstract in some analyzer versions,
      // using firstFragment.source is safer for file paths.
      final source = library.firstFragment.source;

      // Resolve which component that file belongs to
      final importedComponent = fileResolver.resolve(source.fullName);

      if (importedComponent != null) {
        checkViolation(importedComponent: importedComponent, node: node);
      }
    });
  }

  bool _matches(List<String> list, String id) {
    return list.contains(id) || list.any((item) => id.startsWith('$item.'));
  }
}