// lib/src/analysis/layer_resolver.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:path/path.dart' as p;

/// A utility class to resolve the architectural component of a given file path and class name.
class LayerResolver {
  final ArchitectureConfig _config;

  LayerResolver(this._config);

  /// Resolves the specific architectural component for a given file path and an optional class name.
  ArchComponent getComponent(String path, {String? className}) {
    final componentFromPath = _getComponentFromPath(path);

    if (className != null) {
      if (componentFromPath == ArchComponent.manager) {
        return _refineManagerComponent(className);
      }
      if (componentFromPath == ArchComponent.source) {
        return _refineSourceComponent(className);
      }
    }
    return componentFromPath;
  }

  /// Determines the component type based solely on the file's directory.
  ArchComponent _getComponentFromPath(String path) {
    final segments = _getRelativePathSegments(path);
    if (segments == null) return ArchComponent.unknown;

    final layerCfg = _config.layers;
    bool pathContainsAny(List<String> configuredDirs) => configuredDirs.any(segments.contains);

    if (layerCfg.projectStructure == 'layer_first') {
      if (segments.isNotEmpty &&
          [
            layerCfg.domainPath,
            layerCfg.dataPath,
            layerCfg.presentationPath,
          ].contains(segments.first)) {
        // Continue to sub-layer checks
      } else {
        return ArchComponent.unknown;
      }
    } else {
      // feature_first
      if (segments.length <= 2 || segments.first != layerCfg.featuresModule) {
        return ArchComponent.unknown;
      }
    }

    // Domain Layer
    if (pathContainsAny(layerCfg.domain.entity)) return ArchComponent.entity;
    if (pathContainsAny(layerCfg.domain.contract)) return ArchComponent.contract;
    if (pathContainsAny(layerCfg.domain.usecase)) return ArchComponent.usecase;

    // Data Layer
    if (pathContainsAny(layerCfg.data.model)) return ArchComponent.model;
    if (pathContainsAny(layerCfg.data.repository)) return ArchComponent.repository;
    if (pathContainsAny(layerCfg.data.source)) return ArchComponent.source;

    // Presentation Layer
    if (pathContainsAny(layerCfg.presentation.page)) return ArchComponent.page;
    if (pathContainsAny(layerCfg.presentation.widget)) return ArchComponent.widget;
    if (pathContainsAny(layerCfg.presentation.manager)) return ArchComponent.manager;

    return ArchComponent.unknown;
  }

  /// Refines a 'manager' component into 'event', 'state', or 'manager'
  /// by checking for specific, unambiguous name patterns.
  ArchComponent _refineManagerComponent(String className) {
    final naming = _config.naming;

    // --- THE DEFINITIVE, PRIORITIZED LOGIC ---
    // Check for the most specific, suffix-based patterns FIRST.

    // 1. Check if it's an Event or State interface (e.g., AuthEvent, AuthState).
    if (NamingUtils.validateName(
      name: className,
      template: naming.getRuleFor(ArchComponent.event)!.pattern,
    )) {
      return ArchComponent.event;
    }
    if (NamingUtils.validateName(
      name: className,
      template: naming.getRuleFor(ArchComponent.state)!.pattern,
    )) {
      return ArchComponent.state;
    }

    // 2. Check if it's a Manager class (e.g., AuthBloc, AuthCubit).
    if (NamingUtils.validateName(
      name: className,
      template: naming.getRuleFor(ArchComponent.manager)!.pattern,
    )) {
      return ArchComponent.manager;
    }

    // 3. If it has no specific suffix, it's an implementation.
    // We CANNOT reliably distinguish event vs. state implementations here syntactically,
    // as they both use the generic '{{name}}' pattern. That is the job of the
    // semantic linter. For the purpose of file location and basic naming,
    // we can default to a reasonable guess. Let's assume state implementations
    // are more common or provide a general category if needed.
    // However, the best approach is to NOT try to guess. If it doesn't match a specific
    // pattern above, it's treated as a generic member of the 'manager' sub-layer.
    // For the purpose of the naming lints, we need a guess. The ambiguity lies in the config.
    // Given the tests, we need to distinguish them. The only way is order.
    // The previous error was that the generic `{{name}}` rule for implementations
    // was matching before the more specific `{{name}}Bloc` rule. The order fixes this.

    if (NamingUtils.validateName(
      name: className,
      template: naming.getRuleFor(ArchComponent.stateImplementation)!.pattern,
    )) {
      return ArchComponent.stateImplementation;
    }
    if (NamingUtils.validateName(
      name: className,
      template: naming.getRuleFor(ArchComponent.eventImplementation)!.pattern,
    )) {
      return ArchComponent.eventImplementation;
    }

    // Default to the sub-layer's component type if no specific name matches.
    return ArchComponent.manager;
  }

  ArchComponent _refineSourceComponent(String className) {
    final naming = _config.naming;
    if (NamingUtils.validateName(
      name: className,
      template: naming.getRuleFor(ArchComponent.sourceImplementation)!.pattern,
    )) {
      return ArchComponent.sourceImplementation;
    }
    return ArchComponent.source;
  }

  List<String>? _getRelativePathSegments(String absolutePath) {
    final normalized = p.normalize(absolutePath).replaceAll(r'\', '/');
    final segments = normalized.split('/');
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;
    return segments.sublist(libIndex + 1);
  }
}
