// lib/clean_architecture_kit.dart

import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/contract/enforce_entity_contract.dart';
import 'package:clean_architecture_kit/src/lints/contract/enforce_repository_contract.dart';
import 'package:clean_architecture_kit/src/lints/contract/enforce_use_case_contract.dart';
import 'package:clean_architecture_kit/src/lints/dependency/disallow_dependency_instantiation.dart';
import 'package:clean_architecture_kit/src/lints/dependency/disallow_service_locator.dart';
import 'package:clean_architecture_kit/src/lints/dependency/enforce_abstract_data_source_dependency.dart';
import 'package:clean_architecture_kit/src/lints/dependency/enforce_abstract_repository_dependency.dart';
import 'package:clean_architecture_kit/src/lints/error_handling/disallow_throwing_from_repository.dart';
import 'package:clean_architecture_kit/src/lints/error_handling/enforce_exception_on_data_source.dart';
import 'package:clean_architecture_kit/src/lints/error_handling/enforce_try_catch_in_repository.dart';
import 'package:clean_architecture_kit/src/lints/location/enforce_file_and_folder_location.dart';
import 'package:clean_architecture_kit/src/lints/location/enforce_layer_independence.dart';
import 'package:clean_architecture_kit/src/lints/purity/disallow_entity_in_data_source.dart';
import 'package:clean_architecture_kit/src/lints/purity/disallow_flutter_in_domain.dart';
import 'package:clean_architecture_kit/src/lints/purity/disallow_model_in_domain.dart';
import 'package:clean_architecture_kit/src/lints/purity/disallow_model_return_from_repository.dart';
import 'package:clean_architecture_kit/src/lints/purity/disallow_repository_in_presentation.dart';
import 'package:clean_architecture_kit/src/lints/purity/disallow_use_case_in_widget.dart';
import 'package:clean_architecture_kit/src/lints/structure/disallow_public_members_in_implementation.dart';
import 'package:clean_architecture_kit/src/lints/structure/enforce_annotations.dart';
import 'package:clean_architecture_kit/src/lints/structure/enforce_model_inherits_entity.dart';
import 'package:clean_architecture_kit/src/lints/structure/enforce_model_to_entity_mapping.dart';
import 'package:clean_architecture_kit/src/lints/structure/enforce_naming_conventions.dart';
import 'package:clean_architecture_kit/src/lints/structure/enforce_repository_implementation_contract.dart';
import 'package:clean_architecture_kit/src/lints/structure/enforce_type_safety.dart';
import 'package:clean_architecture_kit/src/lints/structure/missing_use_case.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// This is the entry point for the plugin.
PluginBase createPlugin() => CleanArchitectureKitPlugin();

/// The main plugin class for the `clean_architecture_kit` package.
class CleanArchitectureKitPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    // Read and parse the user's configuration.
    final rawConfig = Map<String, dynamic>.from(configs.rules['clean_architecture']?.json ?? {});
    if (rawConfig.isEmpty) return [];
    final config = CleanArchitectureConfig.fromMap(rawConfig);

    // Create shared instances of utilities.
    final layerResolver = LayerResolver(config);

    // Define the lint rules in logical groups for excellent readability.
    final purityAndResponsibilityRules = [
      DisallowModelInDomain(config: config, layerResolver: layerResolver),
      DisallowEntityInDataSource(config: config, layerResolver: layerResolver),
      DisallowRepositoryInPresentation(config: config, layerResolver: layerResolver),
      DisallowModelReturnFromRepository(config: config, layerResolver: layerResolver),
      DisallowUseCaseInWidget(config: config, layerResolver: layerResolver),
      DisallowPublicMembersInImplementation(config: config, layerResolver: layerResolver),
      DisallowFlutterInDomain(config: config, layerResolver: layerResolver),
      EnforceAnnotations(config: config, layerResolver: layerResolver)
    ];

    final dependencyAndStructureRules = [
      EnforceLayerIndependence(config: config, layerResolver: layerResolver),
      EnforceFileAndFolderLocation(config: config, layerResolver: layerResolver),
      DisallowDependencyInstantiation(config: config, layerResolver: layerResolver),
      DisallowServiceLocator(config: config, layerResolver: layerResolver),
    ];

    final contractAndInheritanceRules = [
      EnforceAbstractDataSourceDependency(config: config, layerResolver: layerResolver),
      EnforceAbstractRepositoryDependency(config: config, layerResolver: layerResolver),
      EnforceRepositoryImplementationContract(config: config, layerResolver: layerResolver),
      EnforceModelToEntityMapping(config: config, layerResolver: layerResolver),
      EnforceModelInheritsEntity(config: config, layerResolver: layerResolver),
      EnforceRepositoryContract(config: config, layerResolver: layerResolver),
      EnforceUseCaseContract(config: config, layerResolver: layerResolver),
      EnforceEntityContract(config: config, layerResolver: layerResolver),
    ];

    final errorHandlingRules = [
      EnforceTryCatchInRepository(config: config, layerResolver: layerResolver),
      DisallowThrowingFromRepository(config: config, layerResolver: layerResolver),
      EnforceExceptionOnDataSource(config: config, layerResolver: layerResolver),
    ];

    final conventionAndTypeSafetyRules = [
      EnforceNamingConventions(config: config, layerResolver: layerResolver),
      EnforceTypeSafety(config: config, layerResolver: layerResolver),
    ];

    final codeGenerationRules = [
      MissingUseCase(config: config, layerResolver: layerResolver),
    ];

    // Combine all groups into a single list and return it.
    return [
      ...purityAndResponsibilityRules,
      ...dependencyAndStructureRules,
      ...contractAndInheritanceRules,
      ...errorHandlingRules,
      ...conventionAndTypeSafetyRules,
      ...codeGenerationRules,
    ];
  }
}
