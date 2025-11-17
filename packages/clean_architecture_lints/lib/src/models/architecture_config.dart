// lib/src/models/architecture_config.dart

import 'package:clean_architecture_lints/src/models/annotations_config.dart';
import 'package:clean_architecture_lints/src/models/inheritance_config.dart';
import 'package:clean_architecture_lints/src/models/layer_config.dart';
import 'package:clean_architecture_lints/src/models/naming_config.dart';
import 'package:clean_architecture_lints/src/models/services_config.dart';
import 'package:clean_architecture_lints/src/models/type_safety_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// The main configuration class that parses the entire `architecture_kit` block from the
/// `analysis_options.yaml` file.
class ArchitectureConfig {
  final LayerConfig layers;
  final NamingConfig naming;
  final TypeSafetyConfig typeSafety;
  final InheritanceConfig inheritance;
  final AnnotationsConfig annotations;
  final ServicesConfig services;

  const ArchitectureConfig({
    required this.layers,
    required this.naming,
    required this.typeSafety,
    required this.inheritance,
    required this.annotations,
    required this.services,
  });

  factory ArchitectureConfig.fromMap(Map<String, dynamic> map) {
    return ArchitectureConfig(
      layers: LayerConfig.fromMap(map),
      naming: NamingConfig.fromMap(map.getMap('naming_conventions')),
      typeSafety: TypeSafetyConfig.fromMap(map.getMap('type_safeties')),
      inheritance: InheritanceConfig.fromMap(map.getMap('inheritances')),
      annotations: AnnotationsConfig.fromMap(map.getMap('annotations')),
      services: ServicesConfig.fromMap(map.getMap('services')),
    );
  }
}
