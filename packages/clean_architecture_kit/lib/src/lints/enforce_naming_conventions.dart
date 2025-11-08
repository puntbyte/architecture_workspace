// lib/srcs/lints/enforce_naming_conventions.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/naming_config.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes in architectural layers follow the configured naming conventions,
/// checking for both required patterns and forbidden anti-patterns.
class EnforceNamingConventions extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_naming_conventions',
    problemMessage: 'The name `{0}` does not follow the required naming conventions for a {1}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceNamingConventions({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // 1. Determine the file's location. This is the source of truth.
    final actualSubLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (actualSubLayer == ArchSubLayer.unknown) return;

    // 2. Get the specific naming rule for this location.
    final rule = _getRuleForSubLayer(actualSubLayer, config.naming);
    if (rule == null) return;

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final classType = _getClassTypeForSubLayer(actualSubLayer);

      // --- THE DEFINITIVE AND SIMPLIFIED LOGIC ---

      // 3. First, check for forbidden anti-patterns for this location.
      for (final antiPattern in rule.antiPatterns) {
        if (NamingUtils.validateName(name: className, template: antiPattern)) {
          reporter.atToken(
            node.name,
            LintCode(
              name: _code.name,
              problemMessage: 'The name `$className` uses a forbidden pattern for a $classType (e.g., a simple name is expected, not one with a suffix).',
            ),
          );
          return; // Violation found, stop.
        }
      }

      // 4. If no anti-patterns matched, check against the required positive pattern.
      // THE FIX: The complex "mislocation check" has been completely removed.
      if (!NamingUtils.validateName(name: className, template: rule.pattern)) {
        reporter.atToken(
          node.name,
          LintCode(
            name: _code.name,
            problemMessage: 'The name `$className` does not match the required `${rule.pattern}` convention for a $classType.',
          ),
        );
      }
    });
  }

  NamingRule? _getRuleForSubLayer(ArchSubLayer subLayer, NamingConfig naming) {
    return switch (subLayer) {
      ArchSubLayer.entity => naming.entity,
      ArchSubLayer.model => naming.model,
      ArchSubLayer.useCase => naming.useCase,
      ArchSubLayer.domainRepository => naming.repositoryInterface,
      ArchSubLayer.dataRepository => naming.repositoryImplementation,
      ArchSubLayer.dataSource => naming.dataSourceInterface,
      _ => null,
    };
  }

  String _getClassTypeForSubLayer(ArchSubLayer subLayer) {
    return switch (subLayer) {
      ArchSubLayer.entity => 'Entity',
      ArchSubLayer.model => 'Model',
      ArchSubLayer.useCase => 'UseCase',
      ArchSubLayer.domainRepository => 'Repository Interface',
      ArchSubLayer.dataRepository => 'Repository Implementation',
      ArchSubLayer.dataSource => 'DataSource',
      _ => 'class',
    };
  }
}
