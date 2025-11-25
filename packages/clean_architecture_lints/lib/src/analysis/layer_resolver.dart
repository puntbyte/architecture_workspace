// lib/src/analysis/layer_resolver.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/configs/architecture_config.dart';
import 'package:clean_architecture_lints/src/models/configs/module_config.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:path/path.dart' as p;

class LayerResolver {
  final ArchitectureConfig _config;
  final Map<String, ArchComponent> _componentDirectoryMap;

  LayerResolver(this._config) : _componentDirectoryMap = _createComponentDirectoryMap(_config);

  ArchComponent getComponent(String path, {String? className}) {
    final componentFromPath = _getComponentFromPath(path);

    if (className != null) {
      if (componentFromPath == .manager) {
        return _refineComponent(
          className: className,
          baseComponent: .manager,
          potentialComponents: [
            .eventInterface,
            .stateInterface,
            .manager,
            .stateImplementation,
            .eventImplementation,
          ],
        );
      }
      if (componentFromPath == .source) {
        return _refineComponent(
          className: className,
          baseComponent: .source,
          potentialComponents: [
            .sourceImplementation,
            .sourceInterface,
          ],
        );
      }
    }
    return componentFromPath;
  }

  ArchComponent _getComponentFromPath(String path) {
    final segments = _getRelativePathSegments(path);
    if (segments == null || !_isPathInArchitecturalLayer(segments)) {
      return .unknown;
    }
    for (final segment in segments.reversed) {
      final component = _componentDirectoryMap[segment];
      if (component != null) return component;
    }
    return .unknown;
  }

  ArchComponent _refineComponent({
    required String className,
    required ArchComponent baseComponent,
    required List<ArchComponent> potentialComponents,
  }) {
    for (final component in potentialComponents) {
      final rule = _config.namingConventions.getRuleFor(component);
      if (rule != null && NamingUtils.validateName(name: className, template: rule.pattern)) {
        return component;
      }
    }
    return baseComponent;
  }

  bool _isPathInArchitecturalLayer(List<String> segments) {
    final modules = _config.modules;
    if (modules.type == ModuleType.layerFirst) {
      return segments.isNotEmpty &&
          [modules.domain, modules.data, modules.presentation].contains(segments.first);
    } else {
      return segments.length > 2 && segments.first == modules.features;
    }
  }

  List<String>? _getRelativePathSegments(String absolutePath) {
    final normalized = p.normalize(absolutePath);
    final segments = p.split(normalized);
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;
    return segments.sublist(libIndex + 1);
  }

  static Map<String, ArchComponent> _createComponentDirectoryMap(ArchitectureConfig config) {
    final map = <String, ArchComponent>{};
    final layers = config.layers;

    // Local helper to reduce repetition
    void register(List<String> directories, ArchComponent component) {
      for (final dir in directories) { map[dir] = component; }
    }

    // Domain
    register(layers.domain.entity, ArchComponent.entity);
    register(layers.domain.port, ArchComponent.port);
    register(layers.domain.usecase, ArchComponent.usecase);

    // Data
    register(layers.data.model, ArchComponent.model);
    register(layers.data.repository, ArchComponent.repository);
    register(layers.data.source, ArchComponent.source);

    // Presentation
    register(layers.presentation.page, ArchComponent.page);
    register(layers.presentation.widget, ArchComponent.widget);
    register(layers.presentation.manager, ArchComponent.manager);

    return map;
  }
}
