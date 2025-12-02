// test/src/models/rules/type_rule_test.dart

import 'package:architecture_lints/src/models/configs/type_config.dart';
import 'package:test/test.dart';

void main() {
  group('TypeRule', () {
    group('fromMap', () {
      test('should create instance with valid name and import', () {
        final map = {
          'key': 'test',
          'name': 'FutureEither',
          'import': 'package:core/utils.dart',
        };
        final rule = TypeRule.fromMap(map);

        expect(rule.name, 'FutureEither');
        expect(rule.import, 'package:core/utils.dart');
      });

      test('should create instance with name only', () {
        final map = {
          'key': 'test',
          'name': 'Future',
        };
        final rule = TypeRule.fromMap(map);

        expect(rule.name, 'Future');
        expect(rule.import, isNull);
      });
    });
  });

  group('TypesConfig', () {
    group('Inheritance Logic', () {
      test('should inherit import from "base" key within the group', () {
        final map = {
          'type_definitions': {
            'failure': [
              {'key': 'base', 'name': 'Failure', 'import': 'package:core/failures.dart'},
              {
                'key': 'server',
                'name': 'ServerFailure',
                // Missing import -> Should inherit from base
              },
              {
                'key': 'cache',
                'name': 'CacheFailure',
                'import': 'package:core/specific_cache.dart',
                // Explicit import -> Should override base
              },
            ],
          },
        };

        final config = TypesConfig.fromMap(map);

        // Check inherited
        final server = config.get('failure.server');
        expect(server, isNotNull);
        expect(server!.name, 'ServerFailure');
        expect(server.import, 'package:core/failures.dart');

        // Check override
        final cache = config.get('failure.cache');
        expect(cache, isNotNull);
        expect(cache!.import, 'package:core/specific_cache.dart');
      });

      test('should NOT inherit import if key is "raw"', () {
        final map = {
          'type_definitions': {
            'exception': [
              {'key': 'base', 'name': 'BaseEx', 'import': 'pkg:base.dart'},
              {'key': 'raw', 'name': 'Exception'}, // Should NOT inherit
              {'key': 'other', 'name': 'OtherEx'}, // Should inherit
            ],
          },
        };

        final config = TypesConfig.fromMap(map);

        final raw = config.get('exception.raw');
        expect(raw, isNotNull);
        expect(raw!.import, isNull, reason: 'Raw key should skip inheritance');

        final other = config.get('exception.other');
        expect(other!.import, 'pkg:base.dart');
      });
    });

    group('Complex Parsing', () {
      test('should parse the standard configuration structure', () {
        final map = {
          'type_definitions': {
            'usecase': [
              {'key': 'base', 'name': 'Usecase', 'import': 'pkg:core/usecase.dart'},
              {'key': 'unary', 'name': 'UnaryUsecase'},
            ],
            'exception': [
              {'key': 'raw', 'name': 'Exception'}, // No import
              {'key': 'base', 'name': 'CustomException', 'import': 'pkg:core/error.dart'},
              {'key': 'server', 'name': 'ServerException'}, // Inherits pkg:core/error.dart
            ],
          },
        };

        final config = TypesConfig.fromMap(map);

        // Usecase
        expect(config.get('usecase.unary')!.import, 'pkg:core/usecase.dart');

        // Exception
        // Verify 'raw' did not inherit from 'base' even if they are in the same list
        expect(
          config.get('exception.raw')!.import,
          isNull,
          reason: 'Raw key should not have import from base',
        );

        expect(config.get('exception.server')!.import, 'pkg:core/error.dart');
      });
    });
  });
}
