// lib/src/config/schema/architecture_config.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/dependency_config.dart';
import 'package:architecture_lints/src/config/schema/inheritance_config.dart';
import 'package:architecture_lints/src/config/schema/type_definition.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';

class ArchitectureConfig {
  final List<ComponentConfig> components;
  final List<DependencyConfig> dependencies;
  final List<InheritanceConfig> inheritances;
  final Map<String, TypeDefinition> typeDefinitions;

  const ArchitectureConfig({
    required this.components,
    this.dependencies = const [],
    this.inheritances = const [],
    this.typeDefinitions = const {},
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

    final inheritances = _mapList<InheritanceConfig>(
      yaml,
      ConfigKeys.root.inheritances,
      InheritanceConfig.fromMap,
    );

    // 4. Parse Type Definitions
    final typeDefinitions = <String, TypeDefinition>{};

    // Safely get the 'types' map
    final typesMap = yaml.getMapMap(ConfigKeys.root.types);

    for (final groupEntry in typesMap.entries) {
      final groupKey = groupEntry.key;
      final groupItems = groupEntry.value; // This is a Map<String, dynamic>

      String? currentCascadingImport;

      for (final defEntry in groupItems.entries) {
        final defKey = defEntry.key;
        final fullKey = '$groupKey.$defKey'; // e.g. 'usecase.unary'

        try {
          final def = TypeDefinition.fromDynamic(
            defEntry.value,
            currentImport: currentCascadingImport,
          );

          typeDefinitions[fullKey] = def;

          // Cascade the import to the next item in this group
          if (def.import != null) {
            currentCascadingImport = def.import;
          }
        } catch (e) {
          // print('Failed to parse definition $fullKey: $e');
        }
      }
    }

    return ArchitectureConfig(
      components: components,
      dependencies: dependencies,
      inheritances: inheritances,
      typeDefinitions: typeDefinitions,
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
