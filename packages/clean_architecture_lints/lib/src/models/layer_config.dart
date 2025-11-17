// lib/src/models/layer_config.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// Represents the configuration for the domain layer directories.
class DomainLayerConfig {
  final List<String> entity;
  final List<String> contract;
  final List<String> usecase;

  const DomainLayerConfig({
    required this.entity,
    required this.contract,
    required this.usecase,
  });

  factory DomainLayerConfig.fromMap(Map<String, dynamic> map) {
    return DomainLayerConfig(
      entity: map.getList('entity', orElse: ['entities']),
      contract: map.getList('contract', orElse: ['contracts']),
      usecase: map.getList('usecase', orElse: ['usecases']),
    );
  }
}

/// Represents the configuration for the data layer directories.
class DataLayerConfig {
  final List<String> model;
  final List<String> repository;
  final List<String> source;

  const DataLayerConfig({
    required this.model,
    required this.repository,
    required this.source,
  });

  factory DataLayerConfig.fromMap(Map<String, dynamic> map) {
    return DataLayerConfig(
      model: map.getList('model', orElse: ['models']),
      repository: map.getList('repository', orElse: ['repositories']),
      source: map.getList('source', orElse: ['sources']),
    );
  }
}

/// Represents the configuration for the presentation layer directories.
class PresentationLayerConfig {
  final List<String> page;
  final List<String> widget;
  final List<String> manager;

  const PresentationLayerConfig({
    required this.page,
    required this.widget,
    required this.manager,
  });

  factory PresentationLayerConfig.fromMap(Map<String, dynamic> map) {
    return PresentationLayerConfig(
      page: map.getList('page', orElse: ['pages']),
      widget: map.getList('widget', orElse: ['widgets']),
      manager: map.getList('manager', orElse: ['managers', 'bloc', 'cubit']),
    );
  }
}

/// The parent configuration class for all layer and path definitions.
class LayerConfig {
  final String projectStructure;
  final String featuresModule;
  final String domainPath;
  final String dataPath;
  final String presentationPath;

  final DomainLayerConfig domain;
  final DataLayerConfig data;
  final PresentationLayerConfig presentation;

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

      domain: DomainLayerConfig.fromMap(layerDefs.getMap('domain')),
      data: DataLayerConfig.fromMap(layerDefs.getMap('data')),
      presentation: PresentationLayerConfig.fromMap(layerDefs.getMap('presentation')),
    );
  }

  static String _sanitize(String path) {
    var sanitized = path;
    if (sanitized.startsWith('lib/')) sanitized = sanitized.substring(4);
    if (sanitized.startsWith('/')) sanitized = sanitized.substring(1);
    return sanitized;
  }
}
