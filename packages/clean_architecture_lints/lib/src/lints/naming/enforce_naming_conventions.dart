// lib/src/lints/naming/enforce_naming_conventions.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceNamingConventions extends ArchitectureLintRule {
  // Primary Code (Passed to super)
  static const _patternCode = LintCode(
    name: 'enforce_naming_conventions_pattern',
    problemMessage: 'The name `{0}` does not match the required `{1}` convention for a {2}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  // Secondary Code (Must be distinct)
  static const _antiPatternCode = LintCode(
    name: 'enforce_naming_conventions_antipattern',
    problemMessage: 'The name `{0}` uses a forbidden pattern for a {1}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final List<_ComponentPattern> _sortedPatterns;

  EnforceNamingConventions({
    required super.config,
    required super.layerResolver,
  }) : _sortedPatterns = _createSortedPatterns(config.namingConventions.rules),
        super(code: _patternCode);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (_sortedPatterns.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;

      final actualComponent = layerResolver.getComponent(filePath, className: className);
      if (actualComponent == ArchComponent.unknown) return;

      final rule = config.namingConventions.getRuleFor(actualComponent);
      if (rule == null) return;

      // 1. Pre-Check for Mislocation
      final bestMatch = _sortedPatterns.firstWhereOrNull(
            (p) => NamingUtils.validateName(name: className, template: p.pattern),
      );

      if (bestMatch != null && bestMatch.component != actualComponent) {
        final matchesCurrent = NamingUtils.validateName(name: className, template: rule.pattern);
        if (!matchesCurrent) return;
      }

      // 2. Anti-Pattern Check (Reports the secondary code)
      if (rule.antipattern != null && rule.antipattern!.isNotEmpty) {
        if (NamingUtils.validateName(name: className, template: rule.antipattern!)) {
          reporter.atToken(
            node.name,
            _antiPatternCode, // Uses the secondary code
            arguments: [className, actualComponent.label],
          );
          return;
        }
      }

      // 3. Pattern Check (Reports the primary code)
      if (!NamingUtils.validateName(name: className, template: rule.pattern)) {
        reporter.atToken(
          node.name,
          _patternCode,
          arguments: [className, rule.pattern, actualComponent.label],
        );
      }
    });
  }

  static List<_ComponentPattern> _createSortedPatterns(List<NamingRule> rules) {
    final patterns = rules.expand((rule) {
      return rule.on.map((componentId) {
        final component = ArchComponent.fromId(componentId);
        return component != ArchComponent.unknown
            ? _ComponentPattern(pattern: rule.pattern, component: component)
            : null;
      });
    }).whereNotNull().toList();

    patterns.sort((a, b) => b.pattern.length.compareTo(a.pattern.length));
    return patterns;
  }
}

class _ComponentPattern {
  final String pattern;
  final ArchComponent component;
  const _ComponentPattern({required this.pattern, required this.component});
}