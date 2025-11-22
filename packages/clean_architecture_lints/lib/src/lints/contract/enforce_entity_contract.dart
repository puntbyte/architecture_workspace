// lib/src/lints/contract/enforce_entity_contract.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceEntityContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_entity_contract',
    problemMessage: 'Entities must extend or implement: {0}.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
  );

  static const _defaultRule = InheritanceDetail(
    name: 'Entity',
    import: 'package:clean_architecture_core/clean_architecture_core.dart',
  );

  const EnforceEntityContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.entity) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;

      final element = node.declaredFragment?.element;
      if (element == null) return;

      final customRule = config.inheritances.ruleFor(ArchComponent.entity.id);
      final List<InheritanceDetail> requiredSupertypes;

      if (customRule != null && customRule.required.isNotEmpty) {
        requiredSupertypes = customRule.required;
      } else {
        // Allow either the package version OR the local core version
        requiredSupertypes = [
          _defaultRule,
          InheritanceDetail(
            name: 'Entity',
            import: 'package:${context.pubspec.name}/core/entity/entity.dart',
          ),
        ];
      }

      final hasCorrectSupertype = requiredSupertypes.any(
        (detail) => _hasSupertype(element, detail, context),
      );

      if (!hasCorrectSupertype) {
        // Deduplicate names for the error message (e.g. "Entity or Entity" -> "Entity")
        final requiredNames = requiredSupertypes.map((r) => r.name).toSet().join(' or ');

        reporter.atToken(
          node.name,
          _code,
          arguments: [requiredNames],
        );
      }
    });
  }

  bool _hasSupertype(ClassElement element, InheritanceDetail detail, CustomLintContext context) {
    final expectedUri = _normalizeConfigImport(detail.import, context.pubspec.name);

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      if (superElement.name != detail.name) return false;

      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      return libraryUri == expectedUri;
    });
  }

  String _normalizeConfigImport(String importPath, String packageName) {
    if (importPath.startsWith('package:') || importPath.startsWith('dart:')) {
      return importPath;
    }
    final cleanPath = importPath.startsWith('/') ? importPath.substring(1) : importPath;
    return 'package:$packageName/$cleanPath';
  }
}
