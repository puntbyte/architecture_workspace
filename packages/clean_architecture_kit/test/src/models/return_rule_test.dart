// test/src/models/return_rule_test.dart

import 'package:clean_architecture_kit/src/models/type_safety_config.dart';
import 'package:test/test.dart';

void main() {
  group('ReturnRule', () {
    group('tryFromMap factory', () {
      test('should create a valid rule from a complete map', () {
        final map = {
          'type': 'FutureEither',
          'where': ['useCase', 'domainRepository'],
          'import': 'package:example/core/utils/types.dart',
        };

        final rule = ReturnRule.tryFromMap(map);

        expect(rule, isA<ReturnRule>());
        expect(rule?.type, 'FutureEither');
        expect(rule?.where, ['useCase', 'domainRepository']);
        expect(rule?.importPath, 'package:example/core/utils/types.dart');
      });

      test('should create a valid rule when optional import is missing', () {
        final map = {
          'type': 'FutureEither',
          'where': ['useCase'],
        };

        final rule = ReturnRule.tryFromMap(map);

        expect(rule, isA<ReturnRule>());
        expect(rule?.type, 'FutureEither');
        expect(rule?.where, ['useCase']);
        expect(rule?.importPath, isNull);
      });

      test('should return null if "type" key is missing', () {
        final map = {
          'where': ['useCase'],
        };
        final rule = ReturnRule.tryFromMap(map);
        expect(rule, isNull);
      });

      test('should return null if "type" value is empty', () {
        final map = {
          'type': '',
          'where': ['useCase'],
        };
        final rule = ReturnRule.tryFromMap(map);
        expect(rule, isNull);
      });

      test('should return null if "where" key is missing', () {
        final map = {
          'type': 'FutureEither',
        };
        final rule = ReturnRule.tryFromMap(map);
        expect(rule, isNull);
      });

      test('should return null if "where" value is an empty list', () {
        final map = {
          'type': 'FutureEither',
          'where': [],
        };
        final rule = ReturnRule.tryFromMap(map);
        expect(rule, isNull);
      });

      test('should return null for an empty map', () {
        final map = <String, dynamic>{};
        final rule = ReturnRule.tryFromMap(map);
        expect(rule, isNull);
      });
    });
  });
}
