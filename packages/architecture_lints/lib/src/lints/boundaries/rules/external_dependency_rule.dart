import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/dependency_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ExternalDependencyRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_dep_external',
    problemMessage: 'External dependency violation: "{0}" cannot import "{1}".',
    correctionMessage: 'Remove the import. This layer should be framework-agnostic.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  const ExternalDependencyRule() : super(code: _code);

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

    final rules = config.dependencies.where((rule) {
      return rule.onIds.any((id) => component.id == id || component.id.startsWith('$id.'));
    }).toList();

    if (rules.isEmpty) return;

    final projectName = context.pubspec.name;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;

      // 1. Filter: We only care about External imports
      if (!_isExternalImport(uri, projectName)) return;

      for (final rule in rules) {
        _checkExternal(rule, uri, component, node, reporter);
      }
    });
  }

  bool _isExternalImport(String uri, String projectName) {
    if (uri.startsWith('dart:')) return true;
    if (uri.startsWith('package:')) {
      // It is external if it does NOT start with 'package:my_project/'
      return !uri.startsWith('package:$projectName/');
    }
    // Relative imports are internal
    return false;
  }

  void _checkExternal(
    DependencyConfig rule,
    String uri,
    ComponentConfig component,
    ImportDirective node,
    DiagnosticReporter reporter,
  ) {
    // 1. Check Forbidden
    for (final pattern in rule.forbidden.imports) {
      if (PathMatcher.matches(uri, pattern)) {
        reporter.atNode(
          node.uri, // Fix: Use atNode
          _code,
          arguments: [component.name ?? component.id, uri],
        );
        return;
      }
    }

    // 2. Check Allowed
    // If allowed imports are defined, the URI MUST match one.
    if (rule.allowed.imports.isNotEmpty) {
      bool isAllowed = false;
      for (final pattern in rule.allowed.imports) {
        if (PathMatcher.matches(uri, pattern)) {
          isAllowed = true;
          break;
        }
      }

      if (!isAllowed) {
        reporter.atNode(
          node.uri, // Fix: Use atNode
          _code,
          arguments: [component.name ?? component.id, uri],
        );
      }
    }
  }
}
