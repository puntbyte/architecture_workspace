// test/src/models/parameter_rule_test.dart

import 'package:clean_architecture_kit/src/models/type_safety_config.dart';
import 'package:test/test.dart';

void main() {
  group('ParameterRule', () {
    group('tryFromMap factory', () {
      test('should create a valid rule from a complete map', () {
        final map = {
          'type': 'Id',
          'where': ['domainRepository'],
          'import': 'package:example/core/vo/id.dart',
          'identifier': 'id',
        };

        final rule = ParameterRule.tryFromMap(map);

        expect(rule, isA<ParameterRule>());
        expect(rule?.type, 'Id');
        expect(rule?.where, ['domainRepository']);
        expect(rule?.importPath, 'package:example/core/vo/id.dart');
        expect(rule?.identifier, 'id');
      });

      test('should create a valid rule when optional keys are missing', () {
        final map = {
          'type': '{{name}}Model',
          'where': ['dataSource'],
        };

        final rule = ParameterRule.tryFromMap(map);

        expect(rule, isA<ParameterRule>());
        expect(rule?.type, '{{name}}Model');
        expect(rule?.where, ['dataSource']);
        expect(rule?.importPath, isNull);
        expect(rule?.identifier, isNull);
      });

      test('should return null if "type" key is missing', () {
        final map = {
          'where': ['dataSource'],
        };
        final rule = ParameterRule.tryFromMap(map);
        expect(rule, isNull);
      });

      test('should return null if "type" value is empty', () {
        final map = {
          'type': '',
          'where': ['dataSource'],
        };
        final rule = ParameterRule.tryFromMap(map);
        expect(rule, isNull);
      });

      test('should return null if "where" key is missing', () {
        final map = {
          'type': 'Id',
        };
        final rule = ParameterRule.tryFromMap(map);
        expect(rule, isNull);
      });

      test('should return null if "where" value is an empty list', () {
        final map = {
          'type': 'Id',
          'where': [],
        };
        final rule = ParameterRule.tryFromMap(map);
        expect(rule, isNull);
      });

      test('should return null for an empty map', () {
        final map = <String, dynamic>{};
        final rule = ParameterRule.tryFromMap(map);
        expect(rule, isNull);
      });
    });
  });
}
