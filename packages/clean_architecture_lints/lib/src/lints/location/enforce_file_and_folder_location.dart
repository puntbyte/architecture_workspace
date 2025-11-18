// lib/srcs/lints/location/enforce_file_and_folder_location.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that enforces that a class is located in the correct architectural
/// directory based on its name.
///
/// **Reasoning:** This lint prevents architectural bleed by ensuring that a class
/// whose name clearly identifies it as a specific component (e.g., `UserModel`)
/// is not accidentally placed in the wrong directory (e.g., `/entities`).
/// It cooperates with `enforce_naming_conventions` by focusing only on these
/// clear "mislocation" violations.
class EnforceFileAndFolderLocation extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_file_and_folder_location',
    problemMessage: 'A {0} was found in a "{1}" directory, but it belongs in a "{2}" directory.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final List<_ComponentPattern> _sortedPatterns;

  EnforceFileAndFolderLocation({required super.config, required super.layerResolver})
    : _sortedPatterns = _createSortedPatterns(config.namingConventions.rules),
      super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // If no naming rules are configured, this lint can't determine expectations.
    if (_sortedPatterns.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;

      // 1. Determine the component based on the file's directory ("actual" location).
      final actualComponent = layerResolver.getComponent(filePath);
      if (actualComponent == ArchComponent.unknown) return;

      // 2. Determine the "best guess" component based on the class name ("expected" location).
      final expectedComponent = _getBestGuessComponent(className);

      // 3. If the name-based guess is different from the actual location, it's a violation.
      if (expectedComponent != null && expectedComponent != actualComponent) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [
            expectedComponent.label, // What the class looks like (e.g., "Model")
            actualComponent.label, // Where it was found (e.g., "Entity directory")
            expectedComponent.label, // Where it belongs (e.g., "Model directory")
          ],
        );
      }
    });
  }

  /// Finds the best-fit architectural component by checking the class name against
  /// the pre-sorted list of patterns.
  ArchComponent? _getBestGuessComponent(String className) {
    final bestGuess = _sortedPatterns.firstWhereOrNull(
      (p) => NamingUtils.validateName(name: className, template: p.pattern),
    );
    return bestGuess?.component;
  }

  /// Creates and sorts the list of all known naming patterns once.
  /// Patterns are sorted by length descending to ensure that more specific
  /// patterns (e.g., '{{name}}Model') are checked before more generic ones (e.g., '{{name}}').
  static List<_ComponentPattern> _createSortedPatterns(List<NamingRule> rules) {
    final patterns =
        rules
            .expand((rule) {
              return rule.on.map((componentId) {
                final component = ArchComponent.fromId(componentId);
                return component != ArchComponent.unknown
                    ? _ComponentPattern(pattern: rule.pattern, component: component)
                    : null;
              });
            })
            .whereNotNull()
            .toList()
          // Sort by pattern length, descending.
          ..sort((a, b) => b.pattern.length.compareTo(a.pattern.length));
    return patterns;
  }
}

/// A private helper class to associate a naming pattern with its component.
class _ComponentPattern {
  final String pattern;
  final ArchComponent component;

  const _ComponentPattern({required this.pattern, required this.component});
}
