// test/helpers/test_data.dart
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/models/type_safety_config.dart';

/// Original multi-purpose helper kept for compatibility,
/// defaults to layer_first to be safe in most tests.
CleanArchitectureConfig makeTestConfig({
  String projectStructure = 'layer_first',
  List<String> domainRepositoriesPaths = const ['repositories'],
  List<String> useCasesPaths = const ['usecases'],
  List<ReturnRule> returnRules = const [],
  List<ParameterRule> parameterRules = const [],
}) {
  return CleanArchitectureConfig.fromMap({
    'project_structure': projectStructure,
    'feature_first_paths': {'features_root': 'features'},
    'layer_definitions': {
      'domain': {
        'repositories': domainRepositoriesPaths,
        'usecases': useCasesPaths,
      },
    },
    'type_safety': {
      'returns': returnRules.map((r) => {'type': r.type, 'where': r.where}).toList(),
      'parameters': parameterRules.map((p) => {
        'type': p.type,
        'where': p.where,
        if (p.identifier != null) 'identifier': p.identifier,
      }).toList(),
    },
    'naming_conventions': {},
    'inheritance': {},
    'services': {},
    'generation_options': {},
  });
}

/// Factory for layer-first projects (lib/domain/...).
CleanArchitectureConfig makeLayerFirstConfig({
  List<String> domainRepositoriesPaths = const ['repositories'],
  List<String> useCasesPaths = const ['usecases'],
  List<ReturnRule> returnRules = const [],
  List<ParameterRule> parameterRules = const [],
}) {
  return makeTestConfig(
    projectStructure: 'layer_first',
    domainRepositoriesPaths: domainRepositoriesPaths,
    useCasesPaths: useCasesPaths,
    returnRules: returnRules,
    parameterRules: parameterRules,
  );
}

/// Factory for feature-first projects (lib/features/<feature>/domain/...).
CleanArchitectureConfig makeFeatureFirstConfig({
  String featuresRoot = 'features',
  List<String> domainRepositoriesPaths = const ['contracts'],
  List<String> useCasesPaths = const ['usecases'],
  List<ReturnRule> returnRules = const [],
  List<ParameterRule> parameterRules = const [],
}) {
  // Build the map similarly but indicate feature_first layout
  return CleanArchitectureConfig.fromMap({
    'project_structure': 'feature_first',
    'feature_first_paths': {'features_root': featuresRoot},
    'layer_definitions': {
      'domain': {
        'repositories': domainRepositoriesPaths,
        'usecases': useCasesPaths,
      },
    },
    'type_safety': {
      'returns': returnRules.map((r) => {'type': r.type, 'where': r.where}).toList(),
      'parameters': parameterRules.map((p) => {
        'type': p.type,
        'where': p.where,
        if (p.identifier != null) 'identifier': p.identifier,
      }).toList(),
    },
    'naming_conventions': {},
    'inheritance': {},
    'services': {},
    'generation_options': {},
  });
}
