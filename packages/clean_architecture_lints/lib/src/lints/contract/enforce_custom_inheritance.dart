// lib/src/lints/contract/enforce_custom_inheritance.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
// Correctly import the parent config file to access InheritanceDetail and InheritanceRule
import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A generic lint that enforces all custom inheritance rules defined in the
/// `inheritances` block of the configuration.
class EnforceCustomInheritance extends ArchitectureLintRule {
  static const _requiredCode = LintCode(
    name: 'custom_inheritance_required',
    problemMessage: 'This {0} must extend or implement one of: {1}.',
    correctionMessage: 'Extend or implement one of the required types.',
  );

  static const _forbiddenCode = LintCode(
    name: 'custom_inheritance_forbidden',
    problemMessage: 'This {0} must not extend or implement {1}.',
    correctionMessage: 'Remove the forbidden type from the class definition.',
  );

  final Map<String, InheritanceRule> _rules;

  EnforceCustomInheritance({
    required super.config,
    required super.layerResolver,
  }) : _rules = {
    for (final rule in config.inheritances.rules) rule.on: rule,
  },
        super(code: _requiredCode);

  @override
  void run(
      CustomLintResolver resolver,
      DiagnosticReporter reporter,
      CustomLintContext context,
      ) {
    if (_rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;

      final element = node.declaredFragment?.element;
      if (element == null) return;

      final component = layerResolver.getComponent(
        resolver.source.fullName,
        className: node.name.lexeme,
      );

      if (component == ArchComponent.unknown) return;

      final rule = _rules[component.id];
      if (rule == null) return;

      // 1. ALLOWED CHECK (Short-circuit)
      if (rule.allowed.isNotEmpty) {
        final isAllowed = rule.allowed.any(
              (detail) => _satisfiesDetail(element, detail, context),
        );
        if (isAllowed) return;
      }

      // 2. REQUIRED CHECK
      if (rule.required.isNotEmpty) {
        final hasRequired = rule.required.any(
              (detail) => _satisfiesDetail(element, detail, context),
        );

        if (!hasRequired) {
          // UX FIX: Convert raw component IDs to readable Labels
          final requiredNames = rule.required
              .map(_getDisplayName)
              .join(' or ');

          reporter.atToken(
            node.name,
            _requiredCode,
            arguments: [component.label, requiredNames],
          );
        }
      }

      // 3. FORBIDDEN CHECK
      for (final forbidden in rule.forbidden) {
        if (_satisfiesDetail(element, forbidden, context)) {
          reporter.atToken(
            node.name,
            _forbiddenCode,
            arguments: [
              component.label,
              _getDisplayName(forbidden)
            ],
          );
        }
      }
    });
  }

  /// Returns the class Name or the Component Label for error messages.
  String _getDisplayName(InheritanceDetail detail) {
    if (detail.name != null) return detail.name!;
    if (detail.component != null) {
      return ArchComponent.fromId(detail.component!).label;
    }
    return 'Unknown Type';
  }

  bool _satisfiesDetail(
      ClassElement element,
      InheritanceDetail detail,
      CustomLintContext context,
      ) {
    if (detail.component != null) {
      return _isComponentSupertype(element, detail.component!);
    }

    if (detail.name != null && detail.import != null) {
      return _hasSpecificSupertype(element, detail, context);
    }

    return false;
  }

  bool _isComponentSupertype(ClassElement element, String componentId) {
    final targetComponent = ArchComponent.fromId(componentId);
    if (targetComponent == ArchComponent.unknown) return false;

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      // [Analyzer 8.0.0] Use firstFragment.source
      final source = superElement.library.firstFragment.source;

      final superComp = layerResolver.getComponent(source.fullName);
      return superComp == targetComponent;
    });
  }

  bool _hasSpecificSupertype(
      ClassElement element,
      InheritanceDetail detail,
      CustomLintContext context,
      ) {
    final expectedUri = _normalizeConfigImport(detail.import!, context.pubspec.name);

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
    var cleanPath = importPath;
    if (cleanPath.startsWith('lib/')) {
      cleanPath = cleanPath.substring(4);
    } else if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    return 'package:$packageName/$cleanPath';
  }
}