// lib/src/config/schema/architecture_config.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/dependency_config.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';

class ArchitectureConfig {
  final List<ComponentConfig> components;
  final List<DependencyConfig> dependencies;

  const ArchitectureConfig({
    required this.components,
    this.dependencies = const [],
  });

  factory ArchitectureConfig.empty() => const ArchitectureConfig(components: []);

  /// Constructs an [ArchitectureConfig] from a parsed YAML map.
  /// Uses helpers to extract and validate `components` and `dependencies`.
  factory ArchitectureConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    final components = _mapMap<ComponentConfig>(
      yaml,
      ConfigKeys.root.components,
      ComponentConfig.fromMapEntry,
    );

    final dependencies = _mapList<DependencyConfig>(
      yaml,
      ConfigKeys.root.dependencies,
      DependencyConfig.fromMap,
    );

    return ArchitectureConfig(
      components: components,
      dependencies: dependencies,
    );
  }

  // ---------- Private helpers to reduce redundancy ----------

  /// Extract a map-of-maps from [yaml] at [key], validate it, and convert each `MapEntry` using
  /// [converter].
  static List<T> _mapMap<T>(
    Map<dynamic, dynamic> yaml,
    String key,
    T Function(MapEntry<String, Map<String, dynamic>>) converter,
  ) {
    final raw = yaml[key];

    if (raw != null && raw is! Map) {
      throw FormatException(
        "Invalid configuration: '$key' must be a Map, but found ${raw.runtimeType}.",
      );
    }

    // getMapMap throws/validates and returns an empty map when absent
    final map = yaml.getMapMap(key);
    return map.entries.map(converter).toList();
  }

  /// Extract a list-of-maps from [yaml] at [key], validate it, and convert each map using
  /// [converter].
  static List<T> _mapList<T>(
    Map<dynamic, dynamic> yaml,
    String key,
    T Function(Map<String, dynamic>) converter,
  ) {
    final raw = yaml[key];

    if (raw != null && raw is! List) {
      throw FormatException(
        "Invalid configuration: '$key' must be a List, but found ${raw.runtimeType}.",
      );
    }

    // getMapList throws/validates and returns an empty list when absent
    final list = yaml.getMapList(key);
    return list.map(converter).toList();
  }
}
