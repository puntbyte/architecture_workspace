// test/src/models/services_config_test.dart

import 'package:architecture_lints/src/models/configs/services_config.dart';
import 'package:test/test.dart';

void main() {
  group('ServicesConfig', () {
    group('fromMap factory', () {
      test('should parse a complete map with a nested dependency_injection block', () {
        final map = {
          'services': {
            'dependency_injection': {
              'service_locator_names': ['di.get', 'sl'],
            }
          }
        };

        final config = ServicesConfig.fromMap(map);

        expect(config, isA<ServicesConfig>());
        expect(config.serviceLocator.names, ['di.get', 'sl']);
      });

      test('should create a valid config with defaults when the "services" block is empty', () {
        final map = {'services': {}};
        final config = ServicesConfig.fromMap(map);

        expect(config, isA<ServicesConfig>());
        // Verify that the defaults from the nested DependencyInjectionRule are present.
        expect(config.serviceLocator.names, ['getIt', 'locator', 'sl']);
      });

      test('should create a valid config with defaults when the "services" key is absent', () {
        final map = <String, dynamic>{};
        final config = ServicesConfig.fromMap(map);

        expect(config, isA<ServicesConfig>());
        expect(config.serviceLocator.names, contains('getIt'));
      });
    });
  });
}
