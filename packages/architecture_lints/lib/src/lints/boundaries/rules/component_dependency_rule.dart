import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/boundaries/base/boundary_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ComponentDependencyRule extends BoundaryBaseRule {
  static const _code = LintCode(
    name: 'arch_dep_component',
    problemMessage: 'Dependency Violation: {0} cannot depend on {1}.{2}',
    correctionMessage: 'Remove the dependency to maintain architectural boundaries.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ComponentDependencyRule() : super(code: _code);

  @override
  void checkImport({
    required ImportDirective node,
    required String uri,
    required String? importedPath,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required ComponentContext? component,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required CustomLintContext context,
  }) {
    if (component == null) return;

    if (importedPath == null) {
      // print('[DepRule] Skipped import: "$uri" (Could not resolve path)');
      return;
    }

    final targetComponent = fileResolver.resolve(importedPath);
    if (targetComponent == null) {
      // print('[DepRule] Skipped import: "$uri" (Target not a component)');
      return;
    }

    _validate(node.uri, component, targetComponent, config, reporter);
  }

  @override
  void checkUsage({
    required NamedType node,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required ComponentContext? component,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required CustomLintContext context,
  }) {
    if (component == null) return;

    final element = node.element;
    if (element == null) return;

    final library = element.library;
    // We only care about code inside the project, so ignore SDK/DartCore
    if (library == null || library.isInSdk || library.isDartCore) return;

    final sourcePath = library.firstFragment.source.fullName;
    final targetComponent = fileResolver.resolve(sourcePath);

    if (targetComponent != null) {
      _validate(node, component, targetComponent, config, reporter);
    }
  }

  void _validate(
    AstNode node,
    ComponentContext component,
    ComponentContext targetComponent,
    ArchitectureConfig config,
    DiagnosticReporter reporter,
  ) {
    if (component.id == targetComponent.id) return;

    final rules = config.dependencies.where((rule) => component.matchesAny(rule.onIds)).toList();

    if (rules.isEmpty) {
      // print('[DepRule] No dependency rules for ${component.id}');
      return;
    }

    // Aggregate Rules (Additive)
    final allForbidden = <String>{};
    final allAllowed = <String>{};
    var hasWhitelist = false;

    for (final rule in rules) {
      allForbidden.addAll(rule.forbidden.components);
      if (rule.allowed.components.isNotEmpty) {
        hasWhitelist = true;
        allAllowed.addAll(rule.allowed.components);
      }
    }

    // DEBUG:
    // print('Checking ${component.id} -> ${targetComponent.id}');
    // print('  Forbidden: $allForbidden');
    // print('  Allowed: $allAllowed (Whitelist? $hasWhitelist)');

    // A. Check Forbidden
    if (targetComponent.matchesAny(allForbidden.toList())) {
      _report(reporter, node, component, targetComponent, allAllowed);
      return;
    }

    // B. Check Allowed
    if (hasWhitelist) {
      // If we have a whitelist, target MUST be in it.
      if (!targetComponent.matchesAny(allAllowed.toList())) {
        _report(reporter, node, component, targetComponent, allAllowed);
      }
    }
  }

  void _report(
    DiagnosticReporter reporter,
    AstNode node,
    ComponentContext current,
    ComponentContext target,
    Set<String> allAllowed,
  ) {
    var suggestion = '';
    if (allAllowed.isNotEmpty) {
      final allowedDisplay = allAllowed
          .take(3)
          .map((id) => id.split('.').map((s) => s[0].toUpperCase() + s.substring(1)).join(' '))
          .join(', ');
      suggestion = ' Allowed dependencies: $allowedDisplay${allAllowed.length > 3 ? '...' : ''}.';
    }

    reporter.atNode(
      node,
      _code,
      arguments: [current.displayName, target.displayName, suggestion],
    );
  }
}
