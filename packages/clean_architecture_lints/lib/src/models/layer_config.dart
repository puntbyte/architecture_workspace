// lib/src/models/layer_config.dart

import 'package:clean_architecture_lints/src/models/rules/layer_rules.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// The parent configuration class for all layer and path definitions.
class LayerConfig {
  final String projectStructure;
  final String featuresModule;
  final String domainPath;
  final String dataPath;
  final String presentationPath;

  final DomainLayerRule domain;
  final DataLayerRule data;
  final PresentationLayerRule presentation;

  const LayerConfig({
    required this.projectStructure,
    required this.featuresModule,
    required this.domainPath,
    required this.dataPath,
    required this.presentationPath,
    required this.domain,
    required this.data,
    required this.presentation,
  });

  factory LayerConfig.fromMap(Map<String, dynamic> map) {
    // Parse the new, unified module_definitions block.
    final modules = map.getMap('module_definitions');
    final layersPaths = modules.getMap('layers');
    final layerDefs = map.getMap('layer_definitions');

    return LayerConfig(
      projectStructure: modules.getString('type', orElse: 'feature_first'),
      featuresModule: _sanitize(modules.getString('features', orElse: 'features')),

      // Get the layer-first paths from the new location.
      domainPath: _sanitize(layersPaths.getString('domain', orElse: 'domain')),
      dataPath: _sanitize(layersPaths.getString('data', orElse: 'data')),
      presentationPath: _sanitize(layersPaths.getString('presentation', orElse: 'presentation')),

      domain: DomainLayerRule.fromMap(layerDefs.getMap('domain')),
      data: DataLayerRule.fromMap(layerDefs.getMap('data')),
      presentation: PresentationLayerRule.fromMap(layerDefs.getMap('presentation')),
    );
  }

  static String _sanitize(String path) {
    var sanitized = path;
    // Remove leading slash if present
    if (sanitized.startsWith('/')) sanitized = sanitized.substring(1);
    // Remove lib/ prefix if present (handles both 'lib/' and '/lib/')
    if (sanitized.startsWith('lib/')) sanitized = sanitized.substring(4);
    return sanitized;
  }
}
