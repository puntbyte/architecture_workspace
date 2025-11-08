// test/src/models/type_safety_config_test.dart

import 'package:clean_architecture_kit/src/models/type_safety_config.dart';
import 'package:test/test.dart';

void main() {
  group('TypeSafetyConfig', () {
    group('fromMap factory', () {
      test('should parse a complete map with both returns and parameters rules', () {
        final map = {
          'returns': [
            {
              'type': 'FutureEither',
              'where': ['useCase', 'domainRepository'],
              'import': 'package:example/core/utils/types.dart',
            }
          ],
          'parameters': [
            {
              'type': 'Id',
              'where': ['domainRepository'],
              'identifier': 'id',
            },
            {
              'type': '{{name}}Model',
              'where': ['dataSource'],
            }
          ],
        };

        final config = TypeSafetyConfig.fromMap(map);

        // Assert 'returns' rules were parsed
        expect(config.returns, hasLength(1));
        final returnRule = config.returns.first;
        expect(returnRule, isA<ReturnRule>());
        expect(returnRule.type, 'FutureEither');
        expect(returnRule.where, ['useCase', 'domainRepository']);
        expect(returnRule.importPath, 'package:example/core/utils/types.dart');

        // Assert 'parameters' rules were parsed
        expect(config.parameters, hasLength(2));
        final paramRule1 = config.parameters[0];
        expect(paramRule1, isA<ParameterRule>());
        expect(paramRule1.type, 'Id');
        expect(paramRule1.where, ['domainRepository']);
        expect(paramRule1.identifier, 'id');

        final paramRule2 = config.parameters[1];
        expect(paramRule2.type, '{{name}}Model');
        expect(paramRule2.where, ['dataSource']);
        expect(paramRule2.identifier, isNull); // Correctly handles missing optional key
      });

      test('should parse a map with only returns rules', () {
        final map = {
          'returns': [
            {'type': 'FutureEither', 'where': ['useCase']}
          ]
        };
        final config = TypeSafetyConfig.fromMap(map);

        expect(config.returns, hasLength(1));
        expect(config.parameters, isEmpty);
        expect(config.returns.first.type, 'FutureEither');
      });

      test('should parse a map with only parameters rules', () {
        final map = {
          'parameters': [
            {'type': 'Id', 'where': ['domainRepository']}
          ]
        };
        final config = TypeSafetyConfig.fromMap(map);

        expect(config.returns, isEmpty);
        expect(config.parameters, hasLength(1));
        expect(config.parameters.first.type, 'Id');
      });

      test('should create an empty config from an empty map', () {
        final map = <String, dynamic>{};
        final config = TypeSafetyConfig.fromMap(map);

        expect(config.returns, isEmpty);
        expect(config.parameters, isEmpty);
      });

      test('should gracefully handle null or empty lists in the map', () {
        final map = {
          'returns': null,
          'parameters': [],
        };
        final config = TypeSafetyConfig.fromMap(map);

        expect(config.returns, isEmpty);
        expect(config.parameters, isEmpty);
      });

      test('should ignore malformed entries in the rule lists', () {
        final map = {
          'returns': [
            {'type': 'FutureEither', 'where': ['useCase']}, // Valid
            'not_a_map', // Invalid
            {'type': 'FutureResult'}, // Invalid (missing 'where')
          ],
          'parameters': [
            123, // Invalid
            {'type': 'Id', 'where': ['domainRepository']}, // Valid
          ]
        };
        final config = TypeSafetyConfig.fromMap(map);

        // The parser should only create rules from the valid map entries.
        expect(config.returns, hasLength(1));
        expect(config.returns.first.type, 'FutureEither');
        expect(config.parameters, hasLength(1));
        expect(config.parameters.first.type, 'Id');
      });

      // NEW TEST: ensure the parser accepts different 'where' token formats
      test('accepts varied where token formats', () {
        final map = {
          'returns': [
            {'type': 'FutureEither', 'where': ['domainRepository']},
            {'type': 'FutureEither', 'where': ['domain_repository']},
            {'type': 'FutureEither', 'where': ['domain-repository']},
          ],
        };

        final config = TypeSafetyConfig.fromMap(map);

        // All three entries should be parsed into rules (parser doesn't normalize)
        expect(config.returns, hasLength(3));
        // They should preserve the original 'where' tokens so the runtime matcher can normalize them.
        expect(config.returns[0].where, contains('domainRepository'));
        expect(config.returns[1].where, contains('domain_repository'));
        expect(config.returns[2].where, contains('domain-repository'));
      });
    });
  });
}
