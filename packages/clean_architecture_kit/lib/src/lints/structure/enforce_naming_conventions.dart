// lib/src/lints/enforce_naming_conventions.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/models/naming_config.dart';
import 'package:clean_architecture_kit/src/models/rules/naming_rule.dart';
import 'package:clean_architecture_kit/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A private helper class to associate a naming rule with its architectural role.
class _ComponentRule {
  final String classType;
  final NamingRule rule;
  final ArchSubLayer subLayer;

  const _ComponentRule({
    required this.classType,
    required this.rule,
    required this.subLayer,
  });
}

/// Enforces that classes in architectural layers follow the configured naming conventions.
///
/// This lint is intelligent and cooperative, using a prioritized, multi-step logic:
/// 1.  It first checks if a class is clearly in the wrong location (e.g., a `UserModel`
///     in an `entities` directory). If so, it stays silent to let the more specific
///     `enforce_file_and_folder_location` lint report the error, avoiding noise.
/// 2.  It then checks for forbidden `anti_pattern`s for the class's location.
/// 3.  Finally, it checks if the class name matches the required `pattern`.
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
    final actualSubLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (actualSubLayer == ArchSubLayer.unknown) return;

    final allComponentRules = _getComponentRules(config.naming);
    final ruleForCurrentLocation = allComponentRules.firstWhereOrNull(
      (r) => r.subLayer == actualSubLayer,
    );

    if (ruleForCurrentLocation == null) return;

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;

      // --- PRE-CHECK: Defer to `enforce_file_and_folder_location` if applicable ---
      // This check prevents this lint from firing on a class that is clearly a
      // "location" problem, not a "naming" problem, reducing redundant warnings.
      final sortedRules = List<_ComponentRule>.from(allComponentRules)
        ..sort((a, b) => b.rule.pattern.length.compareTo(a.rule.pattern.length));

      final bestGuessRule = sortedRules.firstWhereOrNull(
        (rule) => NamingUtils.validateName(name: className, template: rule.rule.pattern),
      );

      if (bestGuessRule != null && bestGuessRule.subLayer != actualSubLayer) {
        return; // This is a location problem. Stay silent.
      }

      // --- MAIN NAMING LOGIC ---
      final currentRule = ruleForCurrentLocation.rule;
      // Use the new, clean label property from the enum.
      final classType = actualSubLayer.label;

      // GATE 1: ANTI-PATTERN CHECK
      for (final antiPattern in currentRule.antiPatterns) {
        if (NamingUtils.validateName(name: className, template: antiPattern)) {
          reporter.atToken(
            node.name,
            LintCode(
              name: _code.name,
              problemMessage:
                  'The name `$className` uses a forbidden pattern for a $classType (e.g., a simple '
                  'name is expected, not one with a suffix).',
            ),
          );
          return; // A definitive violation was found. Stop.
        }
      }

      // GATE 2: PATTERN CHECK
      if (!NamingUtils.validateName(name: className, template: currentRule.pattern)) {
        reporter.atToken(
          node.name,
          LintCode(
            name: _code.name,
            problemMessage:
                'The name `$className` does not match the required `${currentRule.pattern}` '
                'convention for a $classType.',
          ),
        );
      }
    });
  }

  /// A helper to create a list of all component rules from the naming configuration.
  List<_ComponentRule> _getComponentRules(NamingConfig naming) {
    return [
      _ComponentRule(classType: 'Entity', rule: naming.entity, subLayer: ArchSubLayer.entity),
      _ComponentRule(classType: 'Model', rule: naming.model, subLayer: ArchSubLayer.model),
      _ComponentRule(classType: 'UseCase', rule: naming.useCase, subLayer: ArchSubLayer.useCase),
      _ComponentRule(
        classType: 'Repository Interface',
        rule: naming.repositoryInterface,
        subLayer: ArchSubLayer.domainRepository,
      ),
      _ComponentRule(
        classType: 'Repository Implementation',
        rule: naming.repositoryImplementation,
        subLayer: ArchSubLayer.dataRepository,
      ),
      _ComponentRule(
        classType: 'DataSource Interface',
        rule: naming.dataSourceInterface,
        subLayer: ArchSubLayer.dataSource,
      ),
      _ComponentRule(
        classType: 'DataSource Implementation',
        rule: naming.dataSourceImplementation,
        subLayer: ArchSubLayer.dataSource,
      ),
    ];
  }
}
