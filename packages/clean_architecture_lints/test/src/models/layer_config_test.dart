// test/src/models/layer_config_test.dart

import 'package:clean_architecture_lints/src/models/layer_config.dart';
import 'package:test/test.dart';

void main() {
  group('LayerConfig', () {
    group('fromMap factory', () {
      test('should parse a complete map with all nested blocks', () {
        final map = {
          'module_definitions': {
            'type': 'layer_first',
            'features': 'my_features',
            'layers': {
              'domain': 'my_domain',
              'data': 'my_data',
              'presentation': 'my_presentation',
            },
          },
          'layer_definitions': {
            'domain': {
              'entity': ['entities', 'models'],
              'contract': ['contracts'],
              'usecase': ['usecases', 'interactors'],
            },
            'data': {
              'model': ['models'],
              'repository': ['repos', 'repositories'],
              'source': ['sources', 'datasources'],
            },
            'presentation': {
              'page': ['pages', 'screens'],
              'widget': ['widgets', 'components'],
              'manager': ['managers', 'bloc', 'cubit', 'controller'],
            },
          },
        };

        final config = LayerConfig.fromMap(map);

        expect(config, isA<LayerConfig>());

        // Check module definitions
        expect(config.projectStructure, 'layer_first');
        expect(config.featuresModule, 'my_features');

        // Check layer paths (should be sanitized)
        expect(config.domainPath, 'my_domain');
        expect(config.dataPath, 'my_data');
        expect(config.presentationPath, 'my_presentation');

        // Check domain layer rules
        expect(config.domain.entity, ['entities', 'models']);
        expect(config.domain.contract, ['contracts']);
        expect(config.domain.usecase, ['usecases', 'interactors']);

        // Check data layer rules
        expect(config.data.model, ['models']);
        expect(config.data.repository, ['repos', 'repositories']);
        expect(config.data.source, ['sources', 'datasources']);

        // Check presentation layer rules
        expect(config.presentation.page, ['pages', 'screens']);
        expect(config.presentation.widget, ['widgets', 'components']);
        expect(config.presentation.manager, ['managers', 'bloc', 'cubit', 'controller']);
      });

      test('should apply default values when optional keys are missing', () {
        final map = <String, dynamic>{};

        final config = LayerConfig.fromMap(map);

        expect(config, isA<LayerConfig>());

        // Check defaults for module definitions
        expect(config.projectStructure, 'feature_first');
        expect(config.featuresModule, 'features');

        // Check defaults for layer paths
        expect(config.domainPath, 'domain');
        expect(config.dataPath, 'data');
        expect(config.presentationPath, 'presentation');

        // Check defaults for domain layer rules
        expect(config.domain.entity, ['entities']);
        expect(config.domain.contract, ['contracts']);
        expect(config.domain.usecase, ['usecases']);

        // Check defaults for data layer rules
        expect(config.data.model, ['models']);
        expect(config.data.repository, ['repositories']);
        expect(config.data.source, ['sources']);

        // Check defaults for presentation layer rules
        expect(config.presentation.page, ['pages']);
        expect(config.presentation.widget, ['widgets']);
        expect(config.presentation.manager, ['managers', 'bloc', 'cubit']);
      });

      test('should sanitize paths by removing lib/ prefix and leading slash', () {
        final map = {
          'module_definitions': {
            'type': 'feature_first',
            'features': 'lib/features',
            'layers': {
              'domain': '/lib/domain',
              'data': '/data',
              'presentation': 'lib/presentation/',
            },
          },
          'layer_definitions': {
            'domain': {},
            'data': {},
            'presentation': {},
          },
        };

        final config = LayerConfig.fromMap(map);

        // Paths should be sanitized
        expect(config.featuresModule, 'features');
        expect(config.domainPath, 'domain');
        expect(config.dataPath, 'data');
        expect(config.presentationPath, 'presentation/');
      });

      test('should handle partial configuration with some defaults', () {
        final map = {
          'module_definitions': {
            'type': 'layer_first',
            // Missing 'features' and 'layers' keys
          },
          'layer_definitions': {
            'domain': {
              'entity': ['custom_entities'],
              // Missing 'contract' and 'usecase' keys
            },
            // Missing 'data' and 'presentation' keys entirely
          },
        };

        final config = LayerConfig.fromMap(map);

        expect(config.projectStructure, 'layer_first');
        expect(config.featuresModule, 'features'); // Default
        expect(config.domainPath, 'domain'); // Default
        expect(config.dataPath, 'data'); // Default
        expect(config.presentationPath, 'presentation'); // Default

        // Domain has custom entity but defaults for others
        expect(config.domain.entity, ['custom_entities']);
        expect(config.domain.contract, ['contracts']); // Default
        expect(config.domain.usecase, ['usecases']); // Default

        // Data and presentation use all defaults
        expect(config.data.model, ['models']);
        expect(config.data.repository, ['repositories']);
        expect(config.data.source, ['sources']);
        expect(config.presentation.page, ['pages']);
        expect(config.presentation.widget, ['widgets']);
        expect(config.presentation.manager, ['managers', 'bloc', 'cubit']);
      });

      test('should handle string values for layer rule lists (single item)', () {
        final map = {
          'module_definitions': {
            'layers': {
              'domain': 'domain',
              'data': 'data',
              'presentation': 'presentation',
            },
          },
          'layer_definitions': {
            'domain': {
              'entity': 'entity', // Single string instead of list
              'contract': ['contracts'],
              'usecase': 'usecase',
            },
            'data': {
              'model': 'model',
              'repository': ['repositories'],
              'source': 'source',
            },
            'presentation': {
              'page': 'page',
              'widget': ['widgets'],
              'manager': 'manager',
            },
          },
        };

        final config = LayerConfig.fromMap(map);

        // Single strings should be wrapped in lists
        expect(config.domain.entity, ['entity']);
        expect(config.domain.contract, ['contracts']);
        expect(config.domain.usecase, ['usecase']);

        expect(config.data.model, ['model']);
        expect(config.data.repository, ['repositories']);
        expect(config.data.source, ['source']);

        expect(config.presentation.page, ['page']);
        expect(config.presentation.widget, ['widgets']);
        expect(config.presentation.manager, ['manager']);
      });

      test('should match the real YAML configuration structure', () {
        // This test uses the exact structure from the provided YAML
        final map = {
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
        };

        final config = LayerConfig.fromMap(map);

        // Verify all values match the YAML
        expect(config.projectStructure, 'feature_first');
        expect(config.featuresModule, 'features');
        expect(config.domainPath, 'domain');
        expect(config.dataPath, 'data');
        expect(config.presentationPath, 'presentation');

        expect(config.domain.entity, ['entities']);
        expect(config.domain.contract, ['contracts']);
        expect(config.domain.usecase, ['usecases']);

        expect(config.data.model, ['models']);
        expect(config.data.repository, ['repositories']);
        expect(config.data.source, ['sources']);

        expect(config.presentation.page, ['pages']);
        expect(config.presentation.widget, ['widgets']);
        expect(config.presentation.manager, ['managers', 'bloc', 'cubit']);
      });
    });
  });
}
