// test/src/models/type_safety_config_test.dart

import 'package:clean_architecture_lints/src/models/rules/type_safety_rule.dart';
import 'package:clean_architecture_lints/src/models/type_safety_config.dart';
import 'package:test/test.dart';

void main() {
  group('TypeSafetyConfig', () {
    group('fromMap factory', () {
      test('should parse a complete list of type safety rules', () {
        final map = {
          'type_safeties': [
            {
              'on': ['usecase', 'contract'],
              'check': 'return',
              'unsafe_type': 'Future',
              'safe_type': 'FutureEither',
            },
            {
              'on': ['contract'],
              'check': 'parameter',
              'identifier': 'id',
              'unsafe_type': 'int',
              'safe_type': 'IntId',
            }
          ]
        };

        final config = TypeSafetyConfig.fromMap(map);

        expect(config.rules, hasLength(2));

        final returnRule = config.rules.first;
        expect(returnRule.check, TypeSafetyTarget.returnType);
        expect(returnRule.unsafeType, 'Future');
        expect(returnRule.safeType, 'FutureEither');

        final paramRule = config.rules.last;
        expect(paramRule.check, TypeSafetyTarget.parameter);
        expect(paramRule.unsafeType, 'int');
        expect(paramRule.identifier, 'id');
      });

      test('should return an empty list when "type_safeties" key is missing', () {
        final map = <String, dynamic>{};
        final config = TypeSafetyConfig.fromMap(map);
        expect(config.rules, isEmpty);
      });

      test('should ignore malformed rules in the list', () {
        final map = {
          'type_safeties': [
            'not_a_map',
            {
              'on': ['usecase'],
              'check': 'return',
              'unsafe_type': 'Future',
              'safe_type': 'FutureEither',
            }, // Valid
            {
              'on': ['contract'],
              'check': 'parameter',
              // Missing 'unsafe_type' and 'safe_type'
            }, // Invalid
          ]
        };
        final config = TypeSafetyConfig.fromMap(map);
        expect(config.rules, hasLength(1));
        expect(config.rules.first.safeType, 'FutureEither');
      });
    });
  });
}
