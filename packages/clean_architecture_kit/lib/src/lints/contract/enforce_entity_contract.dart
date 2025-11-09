// lib/srcs/lints/contract/enforce_entity_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceEntityContract extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_entity_contract',
    problemMessage: 'Entities must implement the base entity class `{0}`.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceEntityContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.entity) return;

    final baseClassName = config.inheritance.entityBaseName;
    final basePath = config.inheritance.entityBasePath;
    if (baseClassName.isEmpty || basePath.isEmpty) return;

    // --- THE DEFINITIVE FIX: Robust Path Resolution ---

    // 1. Determine the fully qualified, expected package URI.
    final String expectedPackageUri;
    if (basePath.startsWith('package:')) {
      // The path is already a full package URI (e.g., from clean_architecture_core).
      expectedPackageUri = basePath;
    } else {
      // It's a relative path from the current project's lib directory.
      final packageName = context.pubspec.name;
      // Sanitize the path to remove any leading slashes.
      final sanitizedPath = basePath.startsWith('/') ? basePath.substring(1) : basePath;
      expectedPackageUri = 'package:$packageName/$sanitizedPath';
    }
    // --- END OF FIX ---

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;

      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      // The core semantic check: is the configured base class in the supertype chain?
      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;

        // Compare the name AND the full, correctly constructed package URI.
        return superElement.name == baseClassName &&
            superElement.library.uri.toString() == expectedPackageUri;
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: [baseClassName]);
      }
    });
  }
}
