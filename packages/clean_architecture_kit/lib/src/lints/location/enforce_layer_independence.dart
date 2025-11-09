// lib/src/lints/location/enforce_layer_independence.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceLayerIndependence extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_layer_independence',
    problemMessage: 'Invalid layer dependency: The {0} layer cannot import from the {1} layer.',
    correctionMessage:
        'Ensure dependencies flow inwards (e.g., Presentation -> Domain, Data -> Domain).',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _illegalDependencies = <ArchLayer, Set<ArchLayer>>{
    ArchLayer.domain: {ArchLayer.data, ArchLayer.presentation},
    ArchLayer.presentation: {ArchLayer.data},
    ArchLayer.data: {ArchLayer.presentation},
  };

  const EnforceLayerIndependence({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final currentLayer = layerResolver.getLayer(resolver.source.fullName);
    if (currentLayer == ArchLayer.unknown) return;

    context.registry.addImportDirective((node) {
      final importedLibrary = node.libraryImport?.importedLibrary;
      if (importedLibrary == null) return;

      final importPath = importedLibrary.firstFragment.libraryFragment?.source.fullName;
      if (importPath == null) return;

      final importedLayer = layerResolver.getLayer(importPath);

      if (importedLayer == ArchLayer.unknown || importedLayer == currentLayer) return;

      final forbiddenLayers = _illegalDependencies[currentLayer];
      if (forbiddenLayers?.contains(importedLayer) ?? false) {
        reporter.atNode(node, _code, arguments: [currentLayer.name, importedLayer.name]);
      }
    });
  }
}
