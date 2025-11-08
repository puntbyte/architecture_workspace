// test/src/models/dependency_injection_config_test.dart

import 'package:clean_architecture_kit/src/models/dependency_injection_config.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyInjectionConfig', () {
    group('fromMap factory', () {
      test('should parse a complete map with all values', () {
        final map = {
          'service_locator_names': ['di', 'get'],
          'use_case_annotations': [
            {
              'import_path': 'package:injectable/injectable.dart',
              'annotation_text': '@Injectable()',
            },
            {
              'import_path': 'package:my_scope/my_scope.dart',
              'annotation_text': '@AuthScope()',
            }
          ]
        };

        final config = DependencyInjectionConfig.fromMap(map);

        expect(config.serviceLocatorNames, ['di', 'get']);
        expect(config.useCaseAnnotations, hasLength(2));
        expect(config.useCaseAnnotations[0], isA<AnnotationConfig>());
        expect(config.useCaseAnnotations[0].annotationText, '@Injectable()');
        expect(config.useCaseAnnotations[1].importPath, 'package:my_scope/my_scope.dart');
      });

      test('should use default values when map is empty', () {
        final map = <String, dynamic>{};
        final config = DependencyInjectionConfig.fromMap(map);

        expect(config.serviceLocatorNames, ['getIt', 'locator', 'sl']);
        expect(config.useCaseAnnotations, isEmpty);
      });

      test('should handle partial data, using defaults for missing keys', () {
        final map = {
          'use_case_annotations': [
            {'annotation_text': '@LazySingleton()'}
          ]
        };

        final config = DependencyInjectionConfig.fromMap(map);

        expect(config.serviceLocatorNames, ['getIt', 'locator', 'sl']); // Default
        expect(config.useCaseAnnotations, hasLength(1));
        expect(config.useCaseAnnotations.first.annotationText, '@LazySingleton()');
      });

      test('should ignore malformed entries in annotations list', () {
        final map = {
          'use_case_annotations': [
            'not_a_map', // Invalid
            {'annotation_text': '@Injectable()'}, // Valid
            123, // Invalid
          ]
        };

        final config = DependencyInjectionConfig.fromMap(map);

        expect(config.useCaseAnnotations, hasLength(1));
        expect(config.useCaseAnnotations.first.annotationText, '@Injectable()');
      });
    });
  });
}
