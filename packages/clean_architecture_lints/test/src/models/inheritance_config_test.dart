// test/src/models/inheritance_config_test.dart

import 'package:clean_architecture_lints/src/models/inheritance_config.dart';
import 'package:clean_architecture_lints/src/models/rules/inheritance_rule.dart';
import 'package:test/test.dart';

void main() {
  group('InheritanceConfig', () {
    group('fromMap factory', () {
      test('should parse a list of custom inheritance rules correctly', () {
        final map = {
          'inheritances': [
            {
              'on': 'use_case',
              'required': [
                {'name': 'MyUnary', 'import': 'package:my_core/my_usecase.dart'},
                {'name': 'MyNullary', 'import': 'package:my_core/my_usecase.dart'},
              ]
            },
            {
              'on': 'widget',
              'forbidden': {'name': 'StatefulWidget', 'import': 'package:flutter/widgets.dart'}
            }
          ]
        };

        final config = InheritanceConfig.fromMap(map);

        expect(config.rules, hasLength(2));

        final useCaseRule = config.rules.first;
        expect(useCaseRule, isA<InheritanceRule>());
        expect(useCaseRule.on, 'use_case');
        expect(useCaseRule.required, hasLength(2));
        expect(useCaseRule.required.first.name, 'MyUnary');
        expect(useCaseRule.forbidden, isEmpty);

        final widgetRule = config.rules[1];
        expect(widgetRule.on, 'widget');
        expect(widgetRule.forbidden, hasLength(1));
        expect(widgetRule.forbidden.first.name, 'StatefulWidget');
        expect(widgetRule.required, isEmpty);
      });

      test('should return an empty list of rules when the "inheritances" key is missing', () {
        final map = <String, dynamic>{};
        final config = InheritanceConfig.fromMap(map);

        expect(config.rules, isEmpty);
      });

      test('should gracefully ignore malformed rules in the list', () {
        final map = {
          'inheritances': [
            'not_a_map', // Invalid entry
            {
              'on': 'entity',
              'required': {'name': 'MyEntity', 'import': 'package:my_core/my_entity.dart'}
            }, // Valid entry
            {'required': 'SomeBaseClass'}, // Invalid entry (missing 'on')
          ]
        };

        final config = InheritanceConfig.fromMap(map);

        // Should only have parsed the one valid rule.
        expect(config.rules, hasLength(1));
        expect(config.rules.first.on, 'entity');
      });
    });
  });
}
