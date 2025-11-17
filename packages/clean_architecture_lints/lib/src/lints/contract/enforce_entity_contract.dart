// lib/src/lints/contract/enforce_entity_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that enforces that concrete Entity classes implement a base Entity class.
class EnforceEntityContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_entity_contract',
    problemMessage: 'Entities must implement the base entity class `{0}`.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _defaultBaseName = 'Entity';
  // Default to the external package.
  static const _defaultBasePath = 'package:clean_architecture_core/entity/entity.dart';

  const EnforceEntityContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  /// A helper to construct the full `package:` URI from a config path.
  String _buildExpectedUri(String configPath, CustomLintContext context) {
    // If the path is already a full package URI, use it directly.
    if (configPath.startsWith('package:')) {
      return configPath;
    }
    // Otherwise, construct it using the current project's name.
    final packageName = context.pubspec.name;
    final sanitizedPath = configPath.startsWith('/') ? configPath.substring(1) : configPath;
    return 'package:$packageName/$sanitizedPath';
  }

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.entity) return;

    final userRule = config.inheritance.rules.firstWhereOrNull((r) => r.on == component.id);
    if (userRule != null) return;

    // Build URIs once, outside the callback
    final expectedCoreUri = _buildExpectedUri(_defaultBasePath, context);
    final expectedProjectUri = 'package:${context.pubspec.name}/core/entity/entity.dart';

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        return superElement.name == _defaultBaseName &&
            (superElement.library.uri.toString() == expectedCoreUri ||
                superElement.library.uri.toString() == expectedProjectUri);
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: [_defaultBaseName]);
      }
    });
  }
}
