// lib/src/analysis/layer_resolver.dart

import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:path/path.dart' as p;

enum ArchLayer {
  domain('Domain'),
  data('Data'),
  presentation('Presentation'),
  unknown('Unknown');

  final String label;

  const ArchLayer(this.label);
}

enum ArchSubLayer {
  // domain
  entity('Entity'),
  useCase('UseCase'),
  domainRepository('Repository Interface'),

  // data
  model('Model'),
  dataSource('DataSource'),
  dataRepository('Repository Implementation'),

  // presentation
  manager('Manager'),
  widget('Widget'),
  pages('Page'),

  // undefined
  unknown('Unknown');

  final String label;

  const ArchSubLayer(this.label);
}

/// A utility class to resolve the architectural layer and sub-layer of a given file path.
class LayerResolver {
  final CleanArchitectureConfig _config;

  LayerResolver(this._config);

  /// Resolves the main architectural layer (Domain, Data, Presentation) for a file path.
  ArchLayer getLayer(String path) {
    final segments = _getRelativePathSegments(path);
    if (segments == null) return ArchLayer.unknown;

    final layerConfig = _config.layers;
    if (layerConfig.projectStructure == 'layer_first') {
      if (segments.isNotEmpty) {
        if (segments.first == layerConfig.domainPath) return ArchLayer.domain;
        if (segments.first == layerConfig.dataPath) return ArchLayer.data;
        if (segments.first == layerConfig.presentationPath) return ArchLayer.presentation;
      }
    } else {
      // feature_first
      if (segments.length > 2 && segments[0] == layerConfig.featuresRootPath) {
        final layerName = segments[2];
        if (layerName == 'domain') return ArchLayer.domain;
        if (layerName == 'data') return ArchLayer.data;
        if (layerName == 'presentation') return ArchLayer.presentation;
      }
    }

    return ArchLayer.unknown;
  }

  /// Resolves the specific architectural sub-layer (e.g., entity, usecase, model) for a file path.
  ArchSubLayer getSubLayer(String path) {
    final layer = getLayer(path);
    if (layer == ArchLayer.unknown) return ArchSubLayer.unknown;

    final pathSegments = _getRelativePathSegments(path);
    if (pathSegments == null) return ArchSubLayer.unknown;

    final layerConfig = _config.layers;

    // A simpler, more direct check. Does the file path contain one of the configured directory
    // names?
    bool containsAny(List<String> configuredDirs) {
      // Does any configured directory name exactly match any segment in the path?
      return configuredDirs.any(pathSegments.contains);
    }

    switch (layer) {
      case ArchLayer.domain:
        if (containsAny(layerConfig.domainEntitiesPaths)) return ArchSubLayer.entity;
        if (containsAny(layerConfig.domainUseCasesPaths)) return ArchSubLayer.useCase;
        if (containsAny(layerConfig.domainRepositoriesPaths)) return ArchSubLayer.domainRepository;

      case ArchLayer.data:
        if (containsAny(layerConfig.dataModelsPaths)) return ArchSubLayer.model;
        if (containsAny(layerConfig.dataDataSourcesPaths)) return ArchSubLayer.dataSource;
        if (containsAny(layerConfig.dataRepositoriesPaths)) return ArchSubLayer.dataRepository;

      case ArchLayer.presentation:
        if (containsAny(layerConfig.presentationManagersPaths)) return ArchSubLayer.manager;
        if (containsAny(layerConfig.presentationWidgetsPaths)) return ArchSubLayer.widget;
        if (containsAny(layerConfig.presentationPagesPaths)) return ArchSubLayer.pages;

      case ArchLayer.unknown:
        break;
    }

    return ArchSubLayer.unknown;
  }

  /// Gets the path segments relative to the `lib` directory.
  List<String>? _getRelativePathSegments(String absolutePath) {
    // Normalize to use forward slashes for consistent splitting.
    final normalized = p.normalize(absolutePath).replaceAll(r'\', '/');
    final segments = p.split(normalized);
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;
    return segments.sublist(libIndex + 1);
  }
}
