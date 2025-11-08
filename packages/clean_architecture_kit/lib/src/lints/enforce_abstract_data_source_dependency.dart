// lib/src/lints/enforce_abstract_data_source_dependency.dart
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule to enforce that Repository Implementations depend on DataSource
/// abstractions (interfaces) and not on concrete implementations.
class EnforceAbstractDataSourceDependency extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_abstract_data_source_dependency',
    problemMessage:
        'Repositories must depend on DataSource abstractions, not concrete implementations.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceAbstractDataSourceDependency({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataRepository) return;

    /// A generic helper to check any dependency type.
    void checkDependency({
      required DartType? type,
      required SyntacticEntity reportNode, // Accepts both AstNode and Token
    }) {
      if (type == null) return;

      final element = type.element;
      if (element is! InterfaceElement) return;

      // 1. Is the dependency a DataSource? (Check its file location)
      // CORRECTED: No unnecessary `?.`
      final source = element.firstFragment.libraryFragment.source;
      if (layerResolver.getSubLayer(source.fullName) != ArchSubLayer.dataSource) {
        return;
      }

      // 2. Is the dependency a concrete class?
      // CORRECTED: Only `ClassElement` has `isAbstract`. Mixins are not a concern.
      if (element is ClassElement && !element.isAbstract) {
        // 3. Find the abstract supertype for a helpful correction message.
        ClassElement? abstractSupertypeElement;
        for (final supertype in element.allSupertypes) {
          final superElement = supertype.element;
          if (superElement is ClassElement && superElement.isAbstract) {
            abstractSupertypeElement = superElement;
            break; // Found the first abstract class, which is sufficient.
          }
        }

        final correction = abstractSupertypeElement != null
            ? 'Depend on the `${abstractSupertypeElement.name}` interface instead.'
            : 'Depend on the abstract interface for this data source.';

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
        checkDependency(
          type: parameter.declaredFragment?.element.type,
          reportNode: parameter, // `parameter` is an AstNode, which is a SyntacticEntity
        );
      }
    });

    // b. Check fields.
    context.registry.addFieldDeclaration((node) {
      for (final variable in node.fields.variables) {
        checkDependency(
          type: variable.declaredFragment?.element.type,
          // CORRECTED: `node.fields.type ?? variable.name` resolves to `SyntacticEntity`.
          reportNode: node.fields.type ?? variable.name,
        );
      }
    });
  }
}
