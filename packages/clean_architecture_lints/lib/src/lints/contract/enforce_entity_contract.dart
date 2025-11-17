// lib/src/lints/contract/enforce_entity_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that enforces that concrete Entity classes implement a base Entity class.
///
/// **Reasoning:** This ensures all entities in the domain layer adhere to a common
/// contract, which is useful for things like equatable implementations or base
/// validation logic. This lint provides an out-of-the-box check for a base `Entity`
/// from `clean_architecture_core` but can be overridden by a custom `inheritances` rule.
class EnforceEntityContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_entity_contract',
    problemMessage: 'Entities must implement the base entity class `{0}`.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  // Hardcoded default for the core architectural contract.
  static const _defaultBaseName = 'Entity';
  static const _defaultBasePath = 'package:clean_architecture_core/entity/entity.dart';

  const EnforceEntityContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule only applies to files in an `entity` directory.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.entity) return;

    // --- LOGIC: Use user's config as an OVERRIDE, otherwise use the default ---
    final userRule = config.inheritance.rules.firstWhereOrNull((r) => r.on == component.id);

    // If the user has defined a custom rule for 'entity', the generic `enforce_inheritance`
    // lint will handle it. This core lint should stay silent to avoid duplicate warnings.
    if (userRule != null) return;

    final expectedPackageUri = _buildExpectedUri(_defaultBasePath, context);

    context.registry.addClassDeclaration((node) {
      // This core rule should not apply to abstract classes (like the base Entity itself).
      if (node.abstractKeyword != null) return;
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      // The core semantic check: is the default base class in the supertype chain?
      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        return superElement.name == _defaultBaseName &&
            superElement.library.uri.toString() == expectedPackageUri;
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: [_defaultBaseName]);
      }
    });
  }

  /// A helper to construct the full `package:` URI from a config path.
  String _buildExpectedUri(String configPath, CustomLintContext context) {
    if (configPath.startsWith('package:')) return configPath;
    final packageName = context.pubspec.name;
    final sanitizedPath = configPath.startsWith('/') ? configPath.substring(1) : configPath;
    return 'package:$packageName/$sanitizedPath';
  }
}
