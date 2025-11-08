// test/src/models/services_config_test.dart

import 'package:clean_architecture_kit/src/models/services_config.dart';
import 'package:test/test.dart';

void main() {
  group('ServicesConfig', () {
    group('fromMap factory', () {
      test('should parse a complete map with a nested dependency_injection block', () {
        final map = {
          'dependency_injection': {
            'service_locator_names': ['getIt'],
            'use_case_annotations': [
              {'annotation_text': '@Injectable()'}
            ]
          }
        };

        final config = ServicesConfig.fromMap(map);

        expect(config, isA<ServicesConfig>());
        // Verify that the nested parser was called correctly.
        expect(config.dependencyInjection.serviceLocatorNames, ['getIt']);
        expect(config.dependencyInjection.useCaseAnnotations, isNotEmpty);
        expect(config.dependencyInjection.useCaseAnnotations.first.annotationText, '@Injectable()');
      });

      test('should create a valid config with defaults when its block is empty', () {
        // Simulates `services: {}` in YAML
        final map = <String, dynamic>{};
        final config = ServicesConfig.fromMap(map);

        expect(config, isA<ServicesConfig>());
        // Verify that the defaults from the nested DependencyInjectionConfig are present.
        expect(config.dependencyInjection.serviceLocatorNames, ['getIt', 'locator', 'sl']);
        expect(config.dependencyInjection.useCaseAnnotations, isEmpty);

      });

      test('should handle the dependency_injection key being completely absent', () {
        // Simulates `services:` block existing but being empty.
        final map = <String, dynamic>{'other_key': 'value'};
        final config = ServicesConfig.fromMap(map);

        expect(config, isA<ServicesConfig>());
        expect(config.dependencyInjection.serviceLocatorNames, ['getIt', 'locator', 'sl']);
        expect(config.dependencyInjection.useCaseAnnotations, isEmpty);
      });
    });
  });
}
