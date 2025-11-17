// lib/src/lints/location/enforce_layer_independence.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces the valid flow of dependencies between architectural layers.
///
/// **Reasoning:** A cornerstone of Clean Architecture is the Dependency Rule, which
/// states that dependencies must flow inwards.
/// - The Domain layer (contracts, entities) must be pure and independent.
/// - The Presentation layer can depend on Domain but not on Data.
/// - The Data layer can depend on Domain but not on Presentation.
class EnforceLayerIndependence extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_layer_independence',
    problemMessage: 'Invalid layer dependency: The {0} layer cannot import from the {1} layer.',
    correctionMessage:
        'Ensure dependencies flow inwards (e.g., Presentation -> Domain, Data -> Domain).',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  /// A declarative map defining the illegal dependency graph.
  /// Key: The component that is importing.
  /// Value: A set of components that it is forbidden to import.
  static const Map<ArchComponent, Set<ArchComponent>> _illegalDependencies = {
    // Domain components are forbidden from importing almost everything.
    ArchComponent.entity: {
      ArchComponent.model,
      ArchComponent.repository,
      ArchComponent.source,
      ArchComponent.manager,
      ArchComponent.widget,
      ArchComponent.page,
    },
    ArchComponent.contract: {
      ArchComponent.model,
      ArchComponent.repository,
      ArchComponent.source,
      ArchComponent.manager,
      ArchComponent.widget,
      ArchComponent.page,
    },
    ArchComponent.usecase: {
      ArchComponent.model,
      ArchComponent.repository,
      ArchComponent.source,
      ArchComponent.manager,
      ArchComponent.widget,
      ArchComponent.page,
    },

    // Presentation components are forbidden from importing Data components.
    ArchComponent.manager: {ArchComponent.model, ArchComponent.repository, ArchComponent.source},
    ArchComponent.widget: {ArchComponent.model, ArchComponent.repository, ArchComponent.source},
    ArchComponent.page: {ArchComponent.model, ArchComponent.repository, ArchComponent.source},

    // Data components are forbidden from importing Presentation components.
    ArchComponent.model: {ArchComponent.manager, ArchComponent.widget, ArchComponent.page},
    ArchComponent.repository: {ArchComponent.manager, ArchComponent.widget, ArchComponent.page},
    ArchComponent.source: {ArchComponent.manager, ArchComponent.widget, ArchComponent.page},
  };

  const EnforceLayerIndependence({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final currentComponent = layerResolver.getComponent(resolver.source.fullName);
    if (currentComponent == ArchComponent.unknown) return;

    // Get the set of forbidden imports for the current component's location.
    final forbiddenImports = _illegalDependencies[currentComponent];
    if (forbiddenImports == null || forbiddenImports.isEmpty) return;

    context.registry.addImportDirective((node) {
      final importedLibrary = node.libraryImport?.importedLibrary;
      if (importedLibrary == null) return;

      final importPath = importedLibrary.firstFragment.libraryFragment?.source.fullName;
      if (importPath == null) return;
      final importedComponent = layerResolver.getComponent(importPath);

      if (importedComponent == ArchComponent.unknown) return;

      // The violation is a simple lookup in our declarative map.
      if (forbiddenImports.contains(importedComponent)) {
        reporter.atNode(node, _code, arguments: [currentComponent.label, importedComponent.label]);
      }
    });
  }
}
