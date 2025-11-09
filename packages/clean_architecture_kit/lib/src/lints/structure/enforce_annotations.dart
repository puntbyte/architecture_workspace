// lib/srcs/lints/enforce_annotations.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_kit/src/utils/extensions/string_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes in certain architectural layers have required annotations
/// or do not have forbidden annotations, based on the configuration.
class EnforceAnnotations extends CleanArchitectureLintRule {
  static const _requiredCode = LintCode(
    name: 'enforce_annotations_required',
    problemMessage: 'This {0} is missing the required annotation: @{1}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _forbiddenCode = LintCode(
    name: 'enforce_annotations_forbidden',
    problemMessage: 'This {0} should not have the annotation: @{1}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceAnnotations({
    required super.config,
    required super.layerResolver,
  }) : super(code: _requiredCode);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer == ArchSubLayer.unknown) return;

    final subLayerNameSnakeCase = subLayer.name.toSnakeCase();

    // THE DEFINITIVE FIX: Use the safe `firstWhereOrNull` extension method.
    final rule = config.annotations.rules.firstWhereOrNull(
      (r) => r.on == subLayerNameSnakeCase,
    );

    if (rule == null || (rule.required.isEmpty && rule.forbidden.isEmpty)) return;

    context.registry.addClassDeclaration((node) {
      final classType = subLayer.label;
      final declaredAnnotations = _getDeclaredAnnotations(node);

      // Check for required annotations.
      for (final requiredAnnotation in rule.required) {
        final annotationName = _normalizeAnnotationText(requiredAnnotation.text);
        if (!declaredAnnotations.contains(annotationName)) {
          reporter.atToken(node.name, _requiredCode, arguments: [classType, annotationName]);
        }
      }

      // Check for forbidden annotations.
      for (final forbiddenAnnotation in rule.forbidden) {
        final annotationName = _normalizeAnnotationText(forbiddenAnnotation.text);
        if (declaredAnnotations.contains(annotationName)) {
          reporter.atToken(node.name, _forbiddenCode, arguments: [classType, annotationName]);
        }
      }
    });
  }

  /// Gets a set of normalized annotation names from a class declaration.
  Set<String> _getDeclaredAnnotations(ClassDeclaration node) {
    return node.metadata
        .map((annotation) => _normalizeAnnotationText(annotation.name.name))
        .toSet();
  }

  /// Normalizes annotation text by removing `@` and `()` for consistent comparison.
  String _normalizeAnnotationText(String text) => text.replaceAll(RegExp('[@()]'), '');
}
