import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/configs/annotations_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceAnnotations extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_annotations',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceAnnotations({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component == ArchComponent.unknown) return;

    final rule = config.annotations.ruleFor(component.id);
    if (rule == null) return;

    // 1. Check Imports (Flag forbidden packages)
    context.registry.addImportDirective((node) {
      final uriString = node.uri.stringValue;
      if (uriString == null) return;

      for (final forbidden in rule.forbidden) {
        if (forbidden.import != null && _matchesImport(uriString, forbidden.import!)) {
          reporter.atNode(
            node,
            _code,
            arguments: [
              'The import `$uriString` is forbidden because it contains the `@${forbidden.name}` annotation.',
            ],
          );
          return;
        }
      }
    });

    // 2. Check Declarations (Classes, Mixins, Enums)
    context.registry.addAnnotatedNode((node) {
      if (node is! ClassDeclaration && node is! MixinDeclaration && node is! EnumDeclaration) {
        return;
      }

      // A. Check Forbidden Annotations (Iterate metadata)
      for (final annotation in node.metadata) {
        final name = annotation.name.name;

        // Resolve source URI
        final element = annotation.element ?? annotation.elementAnnotation?.element;
        final sourceUri = element?.library?.firstFragment.source.uri.toString();

        for (final forbidden in rule.forbidden) {
          if (forbidden.name == name) {
            // If config specifies an import, ensure it matches.
            if (forbidden.import != null) {
              if (sourceUri == null) continue;
              if (!_matchesImport(sourceUri, forbidden.import!)) continue;
            }

            // Report ON THE ANNOTATION node
            reporter.atNode(
              annotation,
              _code,
              arguments: [
                'This ${component.label} must not have the `@${forbidden.name}` annotation.',
              ],
            );
          }
        }
      }

      // B. Check Missing (Required) Annotations
      final nodeName = _getNameToken(node);
      if (nodeName != null) {
        final declaredAnnotations = _getDeclaredAnnotations(node);
        for (final required in rule.required) {
          if (!_hasAnnotation(declaredAnnotations, required)) {
            reporter.atToken(
              nodeName,
              _code,
              arguments: [
                'This ${component.label} is missing the required `@${required.name}` annotation.',
              ],
            );
          }
        }
      }
    });
  }

  Token? _getNameToken(AnnotatedNode node) {
    if (node is ClassDeclaration) return node.name;
    if (node is MixinDeclaration) return node.name;
    if (node is EnumDeclaration) return node.name;
    return null;
  }

  bool _hasAnnotation(List<_ResolvedAnnotation> declared, AnnotationDetail target) {
    return declared.any((declaredAnnotation) {
      if (declaredAnnotation.name != target.name) return false;
      if (target.import != null && declaredAnnotation.sourceUri != null) {
        return _matchesImport(declaredAnnotation.sourceUri!, target.import!);
      }
      return true;
    });
  }

  bool _matchesImport(String actual, String expected) {
    if (actual == expected) return true;
    if (actual.startsWith(expected)) return true;
    if (expected.startsWith('package:') && actual.endsWith(expected.split('/').last)) return true;
    return false;
  }

  List<_ResolvedAnnotation> _getDeclaredAnnotations(AnnotatedNode node) {
    return node.metadata.map((annotation) {
      final name = annotation.name.name;
      final element = annotation.element ?? annotation.elementAnnotation?.element;
      final sourceUri = element?.library?.firstFragment.source.uri.toString();
      return _ResolvedAnnotation(name, sourceUri);
    }).toList();
  }
}

class _ResolvedAnnotation {
  final String name;
  final String? sourceUri;

  _ResolvedAnnotation(this.name, this.sourceUri);
}
