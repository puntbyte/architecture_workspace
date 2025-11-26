// lib/src/models/configs/architecture_config.dart

import 'package:clean_architecture_lints/src/models/configs/annotations_config.dart';
import 'package:clean_architecture_lints/src/models/configs/dependencies_config.dart';
import 'package:clean_architecture_lints/src/models/configs/error_handlers_config.dart';
import 'package:clean_architecture_lints/src/models/configs/inheritances_config.dart';
import 'package:clean_architecture_lints/src/models/configs/layer_config.dart';
import 'package:clean_architecture_lints/src/models/configs/module_config.dart';
import 'package:clean_architecture_lints/src/models/configs/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/models/configs/services_config.dart';
import 'package:clean_architecture_lints/src/models/configs/type_config.dart';
import 'package:clean_architecture_lints/src/models/configs/type_safeties_config.dart';
import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// The main configuration class that parses the entire configuration from
/// `analysis_options.yaml`.
class ArchitectureConfig {
  final ModuleConfig modules;
  final LayerConfig layers;
  final InheritancesConfig inheritances;
  final NamingConventionsConfig namingConventions;
  final TypeSafetiesConfig typeSafeties;
  final DependenciesConfig dependencies;
  final AnnotationsConfig annotations;
  final ServicesConfig services;
  final TypesConfig typeDefinitions;
  final ErrorHandlersConfig errorHandlers;

  const ArchitectureConfig({
    required this.modules,
    required this.layers,
    required this.inheritances,
    required this.namingConventions,
    required this.typeSafeties,
    required this.dependencies,
    required this.annotations,
    required this.services,
    required this.typeDefinitions,
    required this.errorHandlers,
  });

  /// Creates an instance from a configuration map.
  /// Missing sections will result in default configurations.
  factory ArchitectureConfig.fromMap(Map<String, dynamic> map) {
    return ArchitectureConfig(
      modules: ModuleConfig.fromMap(map.asMap(ConfigKey.root.modules)),
      layers: LayerConfig.fromMap(map.asMap(ConfigKey.root.layers)),
      inheritances: InheritancesConfig.fromMap(map),
      namingConventions: NamingConventionsConfig.fromMap(map),
      typeSafeties: TypeSafetiesConfig.fromMap(map),
      dependencies: DependenciesConfig.fromMap(map),
      annotations: AnnotationsConfig.fromMap(map),
      services: ServicesConfig.fromMap(map),
      typeDefinitions: TypesConfig.fromMap(map),
      errorHandlers: ErrorHandlersConfig.fromMap(map),
    );
  }
}
