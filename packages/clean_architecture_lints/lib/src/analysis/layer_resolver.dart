// lib/src/analysis/layer_resolver.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/models/module_config.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:path/path.dart' as p;

class LayerResolver {
  final ArchitectureConfig _config;
  final Map<String, ArchComponent> _componentDirectoryMap;

  LayerResolver(this._config) : _componentDirectoryMap = _createComponentDirectoryMap(_config);

  ArchComponent getComponent(String path, {String? className}) {
    final componentFromPath = _getComponentFromPath(path);

    if (className != null) {
      if (componentFromPath == ArchComponent.manager) {
        return _refineComponent(
          className: className,
          baseComponent: ArchComponent.manager,
          potentialComponents: [
            ArchComponent.eventInterface, ArchComponent.stateInterface,
            ArchComponent.manager, ArchComponent.stateImplementation,
            ArchComponent.eventImplementation,
          ],
        );
      }
      if (componentFromPath == ArchComponent.source) {
        return _refineComponent(
          className: className,
          baseComponent: ArchComponent.source,
          potentialComponents: [
            ArchComponent.sourceImplementation, ArchComponent.sourceInterface,
          ],
        );
      }
    }
    return componentFromPath;
  }

  ArchComponent _getComponentFromPath(String path) {
    final segments = _getRelativePathSegments(path);
    if (segments == null || !_isPathInArchitecturalLayer(segments)) {
      return ArchComponent.unknown;
    }
    for (final segment in segments.reversed) {
      final component = _componentDirectoryMap[segment];
      if (component != null) return component;
    }
    return ArchComponent.unknown;
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
    for (final dir in layers.domain.entity) { map[dir] = ArchComponent.entity; }
    for (final dir in layers.domain.port) { map[dir] = ArchComponent.port; }
    for (final dir in layers.domain.usecase) { map[dir] = ArchComponent.usecase; }
    for (final dir in layers.data.model) { map[dir] = ArchComponent.model; }
    for (final dir in layers.data.repository) { map[dir] = ArchComponent.repository; }
    for (final dir in layers.data.source) { map[dir] = ArchComponent.source; }
    for (final dir in layers.presentation.page) { map[dir] = ArchComponent.page; }
    for (final dir in layers.presentation.widget) { map[dir] = ArchComponent.widget; }
    for (final dir in layers.presentation.manager) { map[dir] = ArchComponent.manager; }
    return map;
  }
}
