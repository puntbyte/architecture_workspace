// test/src/models/type_safety_where_normalization_test.dart

import 'package:clean_architecture_kit/src/models/type_safety_config.dart';
import 'package:test/test.dart';

void main() {
  group('TypeSafetyConfig where-token validation (snake_case only)', () {
    test('accepts valid snake_case tokens', () {
      final map = <String, dynamic>{
        'returns': [
          {
            'type': 'FutureEither',
            'where': ['use_case', 'domain_repository'],
          }
        ],
        'parameters': [],
      };

      final config = TypeSafetyConfig.fromMap(map);

      // Both rules should be accepted (parser should return them)
      expect(config.returns, hasLength(1));
      final rule = config.returns.first;
      expect(rule.where, contains('use_case'));
      expect(rule.where, contains('domain_repository'));
    });

    test('rejects non-snake_case variants (camelCase, hyphen, spaces, uppercase)', () {
      final variants = [
        ['useCase'],
        ['use-case'],
        ['use case'],
        ['UseCase'],
        ['useCase', 'domain_repository'] // mixed -> whole rule should be rejected
      ];

      for (final whereList in variants) {
        final map = <String, dynamic>{
          'returns': [
            {
              'type': 'FutureEither',
              'where': whereList,
            }
          ],
          'parameters': [],
        };

        final config = TypeSafetyConfig.fromMap(map);
        // The invalid rule(s) should be ignored, so no valid 'returns' are produced.
        expect(config.returns, isEmpty, reason: 'Expected rule with where=$whereList to be rejected');
      }
    });

    test('parameter rules also enforce snake_case', () {
      final valid = {
        'parameters': [
          {'type': 'Id', 'where': ['domain_repository'], 'identifier': 'id'}
        ],
      };
      final configValid = TypeSafetyConfig.fromMap(valid);
      expect(configValid.parameters, hasLength(1));

      final invalid = {
        'parameters': [
          {'type': 'Id', 'where': ['domainRepository'], 'identifier': 'id'}
        ],
      };
      final configInvalid = TypeSafetyConfig.fromMap(invalid);
      expect(configInvalid.parameters, isEmpty);
    });
  });
}
