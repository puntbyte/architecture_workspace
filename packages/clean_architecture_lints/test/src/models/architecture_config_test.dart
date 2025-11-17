// test/src/models/architecture_config_test.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/models/rules/type_safety_rule.dart';
import 'package:test/test.dart';

void main() {
  group('ArchitectureConfig', () {
    group('fromMap factory', () {
      test('should parse a complete map matching real YAML structure', () {
        final map = {
          // LayerConfig data
          'module_definitions': {
            'type': 'feature_first',
            'core': 'core',
            'features': 'features',
            'layers': {
              'domain': 'domain',
              'data': 'data',
              'presentation': 'presentation',
            },
          },
          'layer_definitions': {
            'domain': {
              'entity': 'entities',
              'contract': 'contracts',
              'usecase': 'usecases',
            },
            'data': {
              'model': 'models',
              'repository': 'repositories',
              'source': 'sources',
            },
            'presentation': {
              'page': 'pages',
              'widget': 'widgets',
              'manager': ['managers', 'bloc', 'cubit'],
            },
          },

          // NamingConfig data
          'naming_conventions': {
            'entity': {
              'pattern': '{{name}}',
              'antipattern': '{{name}}Entity',
            },
            'model': {
              'pattern': '{{name}}Model',
              'grammar': '{{noun.phrase}}Model',
            },
            'usecase': {
              'pattern': '{{name}}',
              'antipattern': '{{name}}Use(C|c)ase',
              'grammar': '{{verb.present}}{{noun.phrase}}',
            },
            'page': 'pages',
            'widget': '{{name}}Widget',
          },

          // TypeSafetyConfig data
          'type_safeties': [
            {
              'on': ['usecase', 'contract'],
              'check': 'return',
              'unsafe_type': 'Future',
              'safe_type': 'FutureEither',
              'import': 'package:example/core/utils/types.dart',
            },
            {
              'on': 'contract',
              'check': 'parameter',
              'identifier': 'id',
              'unsafe_type': 'int',
              'safe_type': 'IntId',
              'import': 'package:example/core/utils/types.dart',
            },
          ],

          // InheritanceConfig data
          'inheritances': [
            {
              'on': 'entity',
              'required': {
                'name': 'Entity',
                'import': 'package:example/core/entity/entity.dart',
              },
            },
            {
              'on': 'manager',
              'suggested': [
                {
                  'name': 'Bloc',
                  'import': 'package:bloc/bloc.dart',
                },
              ],
            },
          ],

          // AnnotationsConfig data
          'annotations': [
            {
              'on': 'usecase',
              'required': {
                'text': 'Injectable',
                'import': 'package:injectable/injectable.dart',
              },
            },
            {
              'on': 'repository',
              'required': [
                {
                  'text': 'LazySingleton',
                  'import': 'package:injectable/injectable.dart',
                },
              ],
            },
          ],

          // ServicesConfig data
          'services': {
            'dependency_injection': {
              'service_locator_names': ['getIt', 'locator', 'sl'],
            },
          },
        };

        final config = ArchitectureConfig.fromMap(map);

        // Verify config was created
        expect(config, isA<ArchitectureConfig>());

        // Verify LayerConfig
        expect(config.layers.projectStructure, 'feature_first');
        expect(config.layers.featuresModule, 'features');
        expect(config.layers.domainPath, 'domain');
        expect(config.layers.dataPath, 'data');
        expect(config.layers.presentationPath, 'presentation');
        expect(config.layers.domain.entity, ['entities']);
        expect(config.layers.data.model, ['models']);
        expect(config.layers.presentation.manager, ['managers', 'bloc', 'cubit']);

        // Verify NamingConfig (spot check)
        expect(config.naming.getRuleFor(ArchComponent.entity)?.pattern, '{{name}}');
        expect(config.naming.getRuleFor(ArchComponent.model)?.grammar, '{{noun.phrase}}Model');
        expect(config.naming.getRuleFor(ArchComponent.page)?.pattern, 'pages');
        expect(config.naming.getRuleFor(ArchComponent.widget)?.pattern, '{{name}}Widget');

        // Verify TypeSafetyConfig
        expect(config.typeSafety.rules.length, 2);
        expect(config.typeSafety.rules.first.on, ['usecase', 'contract']);
        expect(config.typeSafety.rules.first.check, TypeSafetyTarget.returnType);
        expect(config.typeSafety.rules[1].identifier, 'id');

        // Verify InheritanceConfig
        expect(config.inheritance.rules.length, 2);
        expect(config.inheritance.rules.first.on, 'entity');
        expect(config.inheritance.rules.first.required.first.name, 'Entity');
        expect(config.inheritance.rules[1].suggested.first.name, 'Bloc');

        // Verify AnnotationsConfig
        expect(config.annotations.rules.length, 2);
        expect(config.annotations.rules.first.on, 'usecase');
        expect(config.annotations.rules.first.required.first.text, 'Injectable');
        expect(config.annotations.rules[1].on, 'repository');
        expect(config.annotations.rules[1].required.first.text, 'LazySingleton');

        // Verify ServicesConfig
        expect(config.services.dependencyInjection.serviceLocatorNames, ['getIt', 'locator', 'sl']);
      });

      test('should use defaults for all sections when map is empty', () {
        final map = <String, dynamic>{};

        final config = ArchitectureConfig.fromMap(map);

        expect(config, isA<ArchitectureConfig>());

        // LayerConfig defaults
        expect(config.layers.projectStructure, 'feature_first');
        expect(config.layers.featuresModule, 'features');
        expect(config.layers.domainPath, 'domain');
        expect(config.layers.dataPath, 'data');
        expect(config.layers.presentationPath, 'presentation');
        expect(config.layers.domain.entity, ['entities']);
        expect(config.layers.data.model, ['models']);
        expect(config.layers.presentation.manager, ['managers', 'bloc', 'cubit']);

        // NamingConfig defaults (every component should have a rule)
        expect(config.naming.rules.length, ArchComponent.values.length - 1); // excluding 'unknown'
        expect(config.naming.getRuleFor(ArchComponent.entity)?.pattern, '{{name}}');
        expect(config.naming.getRuleFor(ArchComponent.model)?.pattern, '{{name}}Model');

        // TypeSafetyConfig defaults
        expect(config.typeSafety.rules, isEmpty);

        // InheritanceConfig defaults
        expect(config.inheritance.rules, isEmpty);

        // AnnotationsConfig defaults
        expect(config.annotations.rules, isEmpty);

        // ServicesConfig defaults
        expect(config.services.dependencyInjection.serviceLocatorNames, ['getIt', 'locator', 'sl']);
      });

      test('should handle null sub-maps gracefully', () {
        final map = {
          'module_definitions': null,
          'layer_definitions': null,
          'naming_conventions': null,
          'type_safities': null, // intentional misspelling to test null handling
          'inheritances': null,
          'annotations': null,
          'services': null,
        };

        final config = ArchitectureConfig.fromMap(map);

        expect(config, isA<ArchitectureConfig>());

        // All should fall back to defaults
        expect(config.layers.projectStructure, 'feature_first');
        expect(config.naming.rules.isNotEmpty, true); // Should have defaults
        expect(config.typeSafety.rules, isEmpty);
        expect(config.inheritance.rules, isEmpty);
        expect(config.annotations.rules, isEmpty);
        expect(config.services.dependencyInjection.serviceLocatorNames, ['getIt', 'locator', 'sl']);
      });

      test('should handle partial configuration', () {
        final map = {
          'module_definitions': {
            'type': 'layer_first',
            'features': 'my_features',
          },
          // Missing 'layers' sub-key
          'layer_definitions': {
            'domain': {
              'entity': ['custom_entities'],
            },
            // Missing 'data' and 'presentation' keys
          },
          // Missing all other top-level keys
        };

        final config = ArchitectureConfig.fromMap(map);

        // Verify LayerConfig used provided values where available
        expect(config.layers.projectStructure, 'layer_first');
        expect(config.layers.featuresModule, 'my_features');
        expect(config.layers.domainPath, 'domain'); // Default
        expect(config.layers.domain.entity, ['custom_entities']);
        expect(config.layers.data.model, ['models']); // Default

        // Verify other configs used defaults
        expect(config.naming.rules.isNotEmpty, true);
        expect(config.typeSafety.rules, isEmpty);
        expect(config.inheritance.rules, isEmpty);
        expect(config.annotations.rules, isEmpty);
        expect(config.services.dependencyInjection.serviceLocatorNames, ['getIt', 'locator', 'sl']);
      });

      test('should handle empty lists for rule-based configs', () {
        final map = {
          'module_definitions': {},
          'layer_definitions': {},
          'naming_conventions': {},
          'type_safeties': [],
          'inheritances': [],
          'annotations': [],
          'services': {},
        };

        final config = ArchitectureConfig.fromMap(map);

        expect(config.typeSafety.rules, isEmpty);
        expect(config.inheritance.rules, isEmpty);
        expect(config.annotations.rules, isEmpty);
      });

      test('should create independent instances', () {
        final map = <String, dynamic>{};

        final config1 = ArchitectureConfig.fromMap(map);
        final config2 = ArchitectureConfig.fromMap(map);

        expect(identical(config1, config2), isFalse);
        expect(identical(config1.layers, config2.layers), isFalse);
        expect(config1.layers.projectStructure, config2.layers.projectStructure);
      });
    });
  });
}
