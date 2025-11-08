// lib/srcs/lints/enforce_abstract_repository_dependency.dart

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule to enforce that UseCases depend on Repository abstractions (interfaces)
/// and not on concrete implementations from the data layer.
class EnforceAbstractRepositoryDependency extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_abstract_repository_dependency',
    problemMessage:
        'UseCases must depend on repository abstractions, not concrete implementations.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceAbstractRepositoryDependency({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This lint should only run on files located in a use case directory.
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.useCase) return;

    /// A generic helper to check any dependency type.
    void validate({
      required DartType? type,
      required SyntacticEntity reportNode,
    }) {
      if (type == null) return;
      final element = type.element;
      if (element is! InterfaceElement) return;

      // 1. Is the dependency a Repository Implementation? (Check its file location)
      final source = element.firstFragment.libraryFragment.source;
      if (layerResolver.getSubLayer(source.fullName) != ArchSubLayer.dataRepository) {
        return;
      }

      // 2. Is the dependency a concrete class? This is the violation.
      if (element is ClassElement && !element.isAbstract) {
        // 3. Try to find the abstract interface it implements for a helpful correction.
        ClassElement? abstractSupertypeElement;
        for (final supertype in element.allSupertypes) {
          final superElement = supertype.element;
          if (superElement is ClassElement && superElement.isAbstract) {
            abstractSupertypeElement = superElement;
            break;
          }
        }

        final correction = abstractSupertypeElement != null
            ? 'Depend on the `${abstractSupertypeElement.name}` interface instead.'
            : 'Depend on the abstract repository interface.';

        reporter.atEntity(
          reportNode,
          LintCode(
            name: _code.name,
            problemMessage: _code.problemMessage,
            correctionMessage: correction,
            errorSeverity: _code.errorSeverity,
          ),
        );
      }
    }

    // --- Apply the check comprehensively ---

    // a. Check constructor parameters.
    context.registry.addConstructorDeclaration((node) {
      for (final parameter in node.parameters.parameters) {
        validate(
          type: parameter.declaredFragment?.element.type,
          reportNode: parameter,
        );
      }
    });

    // b. Check fields.
    context.registry.addFieldDeclaration((node) {
      for (final variable in node.fields.variables) {
        validate(
          type: variable.declaredFragment?.element.type,
          reportNode: node.fields.type ?? variable.name,
        );
      }
    });
  }
}
