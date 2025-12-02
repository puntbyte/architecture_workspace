// lib/clean_architecture_lints.dart

import 'dart:convert';
import 'dart:io';

import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/contract/enforce_custom_inheritance.dart';
import 'package:architecture_lints/src/lints/contract/enforce_entity_contract.dart';
import 'package:architecture_lints/src/lints/contract/enforce_port_contract.dart';
import 'package:architecture_lints/src/lints/contract/enforce_repository_contract.dart';
import 'package:architecture_lints/src/lints/contract/enforce_usecase_contract.dart';
import 'package:architecture_lints/src/lints/dependency/'
    'disallow_dependency_instantiation.dart';
import 'package:architecture_lints/src/lints/dependency/'
    'disallow_repository_in_presentation.dart';
import 'package:architecture_lints/src/lints/dependency/disallow_service_locator.dart';
import 'package:architecture_lints/src/lints/dependency/disallow_use_case_in_widget.dart';
import 'package:architecture_lints/src/lints/dependency/'
    'enforce_abstract_data_source_dependency.dart';
import 'package:architecture_lints/src/lints/dependency/'
    'enforce_abstract_repository_dependency.dart';
import 'package:architecture_lints/src/lints/dependency/enforce_layer_independence.dart';
import 'package:architecture_lints/src/lints/error_handling/'
    'disallow_throwing_from_repository.dart';
import 'package:architecture_lints/src/lints/error_handling/'
    'enforce_exception_on_data_source.dart';
import 'package:architecture_lints/src/lints/error_handling/'
    'enforce_try_catch_in_repository.dart';
import 'package:architecture_lints/src/lints/location/enforce_file_and_folder_location.dart';
import 'package:architecture_lints/src/lints/naming/enforce_naming_antipattern.dart';
import 'package:architecture_lints/src/lints/naming/enforce_naming_pattern.dart';
import 'package:architecture_lints/src/lints/naming/enforce_semantic_naming.dart';
import 'package:architecture_lints/src/lints/purity/disallow_entity_in_data_source.dart';
import 'package:architecture_lints/src/lints/purity/disallow_flutter_in_domain.dart';
import 'package:architecture_lints/src/lints/purity/disallow_model_in_domain.dart';
import 'package:architecture_lints/src/lints/purity/enforce_contract_api.dart';
import 'package:architecture_lints/src/lints/purity/require_to_entity_method.dart';
import 'package:architecture_lints/src/lints/structure/enforce_annotations.dart';
import 'package:architecture_lints/src/lints/structure/missing_use_case.dart';
import 'package:architecture_lints/src/lints/type_safety/'
    'disallow_model_return_from_repository.dart';
import 'package:architecture_lints/src/lints/type_safety/enforce_type_safety.dart';
import 'package:architecture_lints/src/models/configs/architecture_config.dart';
import 'package:architecture_lints/src/utils/nlp/language_analyzer.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dictionaryx/dictionary_msa.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The entry point for the `clean_architecture_lints` plugin.
PluginBase createPlugin() => CleanArchitectureLintsPlugin();

/// The main plugin class that initializes and provides all architectural lint rules.
class CleanArchitectureLintsPlugin extends PluginBase {
  /// This method is called once per analysis run to create the list of lint rules.
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    // 1. Get the raw config from analysis_options.yaml
    var rawConfig = Map<String, dynamic>.from(configs.rules['clean_architecture']?.json ?? {});

    // 2. Check for External Config File
    // If 'config_file' is present, we load that file and use it as the source of truth.
    if (rawConfig.containsKey('config_file')) {
      final configPath = rawConfig['config_file'] as String;
      final projectRoot = p.current; // Works because linter runs in project root context usually
      final file = File(p.join(projectRoot, configPath));

      if (file.existsSync()) {
        try {
          final yamlString = file.readAsStringSync();
          final yamlMap = loadYaml(yamlString);
          // Convert YamlMap to Map<String, dynamic> via JSON encoding to ensure type safety
          rawConfig = jsonDecode(jsonEncode(yamlMap)) as Map<String, dynamic>;
        } catch (e) {
          // If parsing fails, we fall back to empty or throw.
          // For a linter, it's safer to return empty list or log print (though print is swallowed).
          // We proceed with empty rules to avoid crashing the analysis server.
          return [];
        }
      }
    }

    // If config is empty at this point, disable lints.
    if (rawConfig.isEmpty) return [];
    final config = ArchitectureConfig.fromMap(rawConfig);

    // 3. Initialize Shared Utilities
    final resolver = LayerResolver(config);
    final analyzer = LanguageAnalyzer(dictionary: DictionaryMSA());

    // 4. Combine all groups into a single list using the spread operator.
    return [
      ..._contractRules(config, resolver),
      ..._dependencyRules(config, resolver),
      ..._errorHandlingRules(config, resolver),
      ..._locationRules(config, resolver),
      ..._namingRules(config, resolver, analyzer),
      ..._purityRules(config, resolver),
      ..._structureRules(config, resolver),
    ];
  }

  List<ArchitectureLintRule> _dependencyRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    DisallowDependencyInstantiation(config: config, layerResolver: resolver),
    DisallowRepositoryInPresentation(config: config, layerResolver: resolver),
    DisallowServiceLocator(config: config, layerResolver: resolver),
    DisallowUseCaseInWidget(config: config, layerResolver: resolver),
    EnforceAbstractDataSourceDependency(config: config, layerResolver: resolver),
    EnforceAbstractRepositoryDependency(config: config, layerResolver: resolver),
    EnforceLayerIndependence(config: config, layerResolver: resolver),
  ];

  List<ArchitectureLintRule> _contractRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    EnforceCustomInheritance(config: config, layerResolver: resolver),
    EnforceEntityContract(config: config, layerResolver: resolver),
    EnforcePortContract(config: config, layerResolver: resolver),
    EnforceRepositoryContract(config: config, layerResolver: resolver),
    EnforceUsecaseContract(config: config, layerResolver: resolver),
  ];

  List<ArchitectureLintRule> _errorHandlingRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    DisallowThrowingFromRepository(config: config, layerResolver: resolver),
    EnforceExceptionOnDataSource(config: config, layerResolver: resolver),
    EnforceTryCatchInRepository(config: config, layerResolver: resolver),
  ];

  List<ArchitectureLintRule> _locationRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    EnforceFileAndFolderLocation(config: config, layerResolver: resolver),
  ];

  List<ArchitectureLintRule> _namingRules(
    ArchitectureConfig config,
    LayerResolver resolver,
    LanguageAnalyzer analyzer,
  ) => [
    EnforceNamingAntipattern(config: config, layerResolver: resolver),
    EnforceNamingPattern(config: config, layerResolver: resolver),
    EnforceSemanticNaming(config: config, layerResolver: resolver, analyzer: analyzer),
  ];

  List<ArchitectureLintRule> _purityRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    DisallowEntityInDataSource(config: config, layerResolver: resolver),
    DisallowFlutterInDomain(config: config, layerResolver: resolver),
    DisallowModelInDomain(config: config, layerResolver: resolver),
    DisallowModelReturnFromRepository(config: config, layerResolver: resolver),
    EnforceContractApi(config: config, layerResolver: resolver),
    RequireToEntityMethod(config: config, layerResolver: resolver),
  ];

  List<ArchitectureLintRule> _structureRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    EnforceAnnotations(config: config, layerResolver: resolver),
    EnforceTypeSafety(config: config, layerResolver: resolver),
    MissingUseCase(config: config, layerResolver: resolver),
  ];
}
