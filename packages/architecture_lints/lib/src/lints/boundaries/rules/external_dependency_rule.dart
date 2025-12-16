import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/policies/dependency_policy.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/boundaries/base/boundary_base_rule.dart';
import 'package:architecture_lints/src/lints/boundaries/logic/package_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ExternalDependencyRule extends BoundaryBaseRule with PackageLogic {
  static const _code = LintCode(
    name: 'arch_dep_external',
    problemMessage: 'External dependency violation: {0} cannot depend on "{1}".',
    correctionMessage: 'Remove the usage. This layer should be framework-agnostic.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ExternalDependencyRule() : super(code: _code);

  List<DependencyPolicy> _getRules(ArchitectureConfig config, ComponentContext? component) {
    if (component == null) return [];
    return config.dependencies.where((rule) {
      return component.matchesAny(rule.onIds);
    }).toList();
  }

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
    required CustomLintContext context, // Added
  }) {
    final rules = _getRules(config, component);
    if (rules.isEmpty) return;

    final projectName = context.pubspec.name; // Now available
    if (!isExternalUri(uri, projectName)) return;

    _validate(node, uri, rules, component!, reporter);
  }

  @override
  void checkUsage({
    required NamedType node,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required ComponentContext? component,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required CustomLintContext context, // Added
  }) {
    final rules = _getRules(config, component);
    if (rules.isEmpty) return;

    final uri = getUriFromNode(node);
    if (uri == null) return;

    final projectName = context.pubspec.name; // Now available
    if (!isExternalUri(uri, projectName)) return;

    _validate(node, uri, rules, component!, reporter);
  }

  void _validate(
      AstNode node,
      String uri,
      List<DependencyPolicy> rules,
      ComponentContext component,
      DiagnosticReporter reporter,
      ) {
    for (final rule in rules) {
      // A. Check Forbidden
      if (matchesAnyPattern(uri, rule.forbidden.imports)) {
        reporter.atNode(node, _code, arguments: [component.displayName, uri]);
        return;
      }

      // B. Check Allowed
      if (rule.allowed.imports.isNotEmpty) {
        if (!matchesAnyPattern(uri, rule.allowed.imports)) {
          reporter.atNode(node, _code, arguments: [component.displayName, uri]);
        }
      }
    }
  }
}
