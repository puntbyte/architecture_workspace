// lib/src/lints/structure/enforce_model_inherits_entity.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that enforces that a Model class must extend or implement a domain Entity.
///
/// This ensures structural compatibility by checking the definition location of a
/// Model's supertypes.
class EnforceModelInheritsEntity extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_model_inherits_entity',
    problemMessage: 'Classes in a models directory must extend or implement a domain Entity.',
    correctionMessage:
        'Add `extends YourEntity` or `implements YourEntity` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceModelInheritsEntity({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This lint should only run on files located in a model directory.
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.model) return;

    context.registry.addClassDeclaration((node) {
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      final hasEntitySupertype = classElement.allSupertypes.any((supertype) {
        final source = supertype.element.firstFragment.libraryFragment.source;
        return layerResolver.getSubLayer(source.fullName) == ArchSubLayer.entity;
      });

      if (!hasEntitySupertype) {
        // We still provide a helpful, convention-based suggestion in the error.
        final modelName = node.name.lexeme;
        final baseName = _extractBaseName(modelName, config.naming.model.pattern) ?? '[YourEntity]';
        final expectedEntityName = config.naming.entity.pattern.replaceAll('{{name}}', baseName);

        reporter.atToken(
          node.name,
          LintCode(
            name: _code.name,
            problemMessage: 'The model `$modelName` must extend or implement a domain Entity.',
            correctionMessage: 'Consider adding `extends $expectedEntityName`.',
            errorSeverity: _code.errorSeverity,
          ),
        );
      }
    });
  }

  /// Extracts the base name from a class name based on a template.
  String? _extractBaseName(String name, String template) {
    if (template.isEmpty) return null;
    final pattern = template.replaceAll('{{name}}', '([A-Z][a-zA-Z0-9]+)');
    final regex = RegExp('^$pattern\$');
    final match = regex.firstMatch(name);
    return match?.group(1);
  }
}
