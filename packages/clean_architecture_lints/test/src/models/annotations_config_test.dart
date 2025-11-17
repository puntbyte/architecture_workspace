// test/src/models/annotations_config_test.dart

import 'package:clean_architecture_lints/src/models/annotations_config.dart';
import 'package:test/test.dart';

void main() {
  group('AnnotationsConfig', () {
    group('fromMap factory', () {
      test('should parse a complete list of annotation rules', () {
        final map = {
          'annotations': [
            {
              'on': 'use_case',
              'required': {'text': '@Injectable()'}
            },
            {
              'on': 'entity',
              'forbidden': [
                {'text': '@Injectable()'},
                {'text': '@Singleton()'},
              ]
            },
            {
              'on': 'widget',
              'suggested': {
                'text': '@immutable',
                'message': 'Consider making widgets immutable.'
              }
            }
          ]
        };

        final config = AnnotationsConfig.fromMap(map);

        expect(config.rules, hasLength(3));

        final useCaseRule = config.ruleFor('use_case');
        expect(useCaseRule, isNotNull);
        expect(useCaseRule!.required, hasLength(1));
        expect(useCaseRule.required.first.text, '@Injectable()');

        final entityRule = config.ruleFor('entity');
        expect(entityRule, isNotNull);
        expect(entityRule!.forbidden, hasLength(2));
        expect(entityRule.forbidden.last.text, '@Singleton()');

        final widgetRule = config.ruleFor('widget');
        expect(widgetRule, isNotNull);
        expect(widgetRule!.suggested, hasLength(1));
        expect(widgetRule.suggested.first.message, contains('immutable'));
      });

      test('should return an empty list of rules when the "annotations" key is missing', () {
        final map = <String, dynamic>{};
        final config = AnnotationsConfig.fromMap(map);
        expect(config.rules, isEmpty);
      });

      test('should gracefully ignore malformed rules in the list', () {
        final map = {
          'annotations': [
            'not_a_map', // Invalid
            {'on': 'use_case', 'required': {'text': '@Injectable()'}}, // Valid
            {'required': {'text': '@Singleton()'}}, // Invalid (missing 'on')
          ]
        };

        final config = AnnotationsConfig.fromMap(map);
        expect(config.rules, hasLength(1));
        expect(config.rules.first.on, 'use_case');
      });

      test('ruleFor helper should return null when no rule is found', () {
        final config = AnnotationsConfig.fromMap({});
        expect(config.ruleFor('non_existent_component'), isNull);
      });

      test('requiredFor helper should return an empty list when no rule is found', () {
        final config = AnnotationsConfig.fromMap({});
        expect(config.requiredFor('non_existent_component'), isEmpty);
      });
    });
  });
}
