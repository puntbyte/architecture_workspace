// test/src/models/layer_config_test.dart

import 'package:clean_architecture_kit/src/models/layer_config.dart';
import 'package:test/test.dart';

void main() {
  group('LayerConfig', () {
    group('fromMap factory', () {
      test('should parse feature-first config with custom values', () {
        final map = {
          'project_structure': 'feature_first',
          'feature_first_paths': {'features_root': 'modules'},
          'layer_definitions': {
            'domain': {'repositories': ['contracts']}
          }
        };
        final config = LayerConfig.fromMap(map);

        expect(config.projectStructure, 'feature_first');
        expect(config.featuresRootPath, 'modules');
        expect(config.domainRepositoriesPaths, ['contracts']);
        expect(config.domainEntitiesPaths, ['entities']); // Default
      });

      test('should parse layer-first config with custom values', () {
        final map = {
          'project_structure': 'layer_first',
          'layer_first_paths': {'domain': 'core'},
          'layer_definitions': {
            'presentation': {'widgets': ['ui/components']}
          }
        };
        final config = LayerConfig.fromMap(map);

        expect(config.projectStructure, 'layer_first');
        expect(config.domainPath, 'core');
        expect(config.presentationWidgetsPaths, ['ui/components']);
        expect(config.dataPath, 'data'); // Default
      });

      test('should use all default values when map is empty', () {
        final map = <String, dynamic>{};
        final config = LayerConfig.fromMap(map);

        expect(config.projectStructure, 'feature_first');
        expect(config.featuresRootPath, 'features');
        expect(config.domainPath, 'domain');
        expect(config.domainEntitiesPaths, ['entities']);
        expect(config.domainRepositoriesPaths, ['contracts']);
        expect(config.dataModelsPaths, ['models']);
        expect(config.presentationManagersPaths, ['managers', 'bloc', 'cubit', 'provider']);
      });

      test('should sanitize paths by removing leading slashes', () {
        final map = {
          'feature_first_paths': {'features_root': '/features'},
          'layer_first_paths': {'domain': '/domain_layer'}
        };
        final config = LayerConfig.fromMap(map);

        expect(config.featuresRootPath, 'features');
        expect(config.domainPath, 'domain_layer');
      });
    });
  });
}
