// lib/src/lints/dependency/enforce_abstract_data_source_dependency.dart

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule to enforce that Repository Implementations depend on DataSource
/// abstractions (interfaces) and not on concrete implementations.
class EnforceAbstractDataSourceDependency extends ArchitectureLintRule {
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
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    void validate({
      required DartType? type,
      required SyntacticEntity reportNode,
    }) {
      if (type == null) return;
      final element = type.element;
      if (element is! InterfaceElement) return;

      final source = element.firstFragment.libraryFragment.source;
      final isConcreteDataSource =
          layerResolver.getComponent(source.fullName, className: element.name) ==
              ArchComponent.sourceImplementation &&
          element is ClassElement &&
          !element.isAbstract;

      if (isConcreteDataSource) {
        final abstractSupertype = element.allSupertypes.firstWhereOrNull(
          (supertype) {
            final superElement = supertype.element;
            // THE DEFINITIVE FIX: Use the correct fragment chain to get the source.
            final superSource = superElement.firstFragment.libraryFragment.source;
            return (superElement is ClassElement && superElement.isAbstract) &&
                layerResolver.getComponent(superSource.fullName) == ArchComponent.sourceInterface;
          },
        );

        final correction = abstractSupertype != null
            ? 'Depend on the `${abstractSupertype.element.name}` interface instead.'
            : 'Depend on the abstract DataSource interface.';

        reporter.atEntity(
          reportNode,
          LintCode(
            name: _code.name,
            problemMessage: _code.problemMessage,
            correctionMessage: correction,
          ),
        );
      }
    }

    context.registry.addConstructorDeclaration((node) {
      for (final parameter in node.parameters.parameters) {
        validate(type: parameter.declaredFragment?.element.type, reportNode: parameter);
      }
    });

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
