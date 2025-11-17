// test/helpers/test_data.dart

import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/models/rules/type_safety_rule.dart';

/// A single, powerful test data factory for creating a complete and valid
/// [ArchitectureConfig] object for use in unit tests.
///
/// It provides sensible defaults for all configuration options and allows any
/// specific property to be overridden by passing it as a parameter.
ArchitectureConfig makeConfig({
  // module_definitions
  String projectStructure = 'feature_first',
  String coreModule = 'core',
  String featuresModule = 'features',
  String domainLayerPath = 'domain',
  String dataLayerPath = 'data',
  String presentationLayerPath = 'presentation',

  // layer_definitions
  dynamic entityDir = 'entities',
  dynamic contractDir = 'contracts',
  dynamic usecaseDir = 'usecases',
  dynamic modelDir = 'models',
  dynamic repositoryDir = 'repositories',
  dynamic sourceDir = 'sources',
  dynamic pageDir = 'pages',
  dynamic widgetDir = 'widgets',
  dynamic managerDir = const ['managers', 'bloc', 'cubit'],

  // naming_conventions (use `dynamic` to accept both String and Map)
  dynamic entityNaming = '{{name}}',
  dynamic modelNaming = '{{name}}Model',
  dynamic useCaseNaming = '{{name}}',
  dynamic eventNaming = '{{name}}Event',
  dynamic stateNaming = '{{name}}State',
  // ... add other naming configs as needed

  // type_safeties (pass rule objects for type safety)
  List<TypeSafetyRule> typeSafetyRules = const [],

  // inheritances & annotations (pass raw maps as they are simpler for tests)
  List<Map<String, dynamic>> inheritanceRules = const [],
  List<Map<String, dynamic>> annotationRules = const [],

  // services
  List<String> serviceLocatorNames = const ['getIt', 'locator', 'sl'],
}) {
  return ArchitectureConfig.fromMap({
    // New, unified module_definitions block
    'module_definitions': {
      'type': projectStructure,
      'core': coreModule,
      'features': featuresModule,
      'layers': {
        'domain': domainLayerPath,
        'data': dataLayerPath,
        'presentation': presentationLayerPath,
      }
    },
    'layer_definitions': {
      'domain': {'entity': entityDir, 'contract': contractDir, 'usecase': usecaseDir},
      'data': {'model': modelDir, 'repository': repositoryDir, 'source': sourceDir},
      'presentation': {'page': pageDir, 'widget': widgetDir, 'manager': managerDir},
    },

    'naming_conventions': {
      'entity': entityNaming,
      'model': modelNaming,
      'usecase': useCaseNaming,
      'event.interface': eventNaming,
      'state.interface': stateNaming,
    },

    'type_safeties': typeSafetyRules.map((r) => {
      'on': r.on,
      'check': r.check.name, // Use the enum's name
      'unsafe_type': r.unsafeType,
      'safe_type': r.safeType,
      if (r.identifier != null) 'identifier': r.identifier,
    }).toList(),

    'inheritances': inheritanceRules,
    'annotations': annotationRules,

    'services': {
      'dependency_injection': {'service_locator_names': serviceLocatorNames}
    },
  });
}
