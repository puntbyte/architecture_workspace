// test/src/models/naming_config_test.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/naming_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';
import 'package:test/test.dart';

void main() {
  group('NamingConfig', () {
    group('fromMap factory', () {
      test('should parse a map with custom string and map values', () {
        final map = {
          'naming_conventions': {
            // Custom string value
            'model': '{{name}}Dto',
            // Custom map value
            'entity': {
              'pattern': '{{name}}Object',
              'antipattern': '{{name}}Entity',
            },
            // Custom grammar value
            'usecase': {
              'grammar': '{{verb}}{{noun}}Action'
            }
          }
        };
        final config = NamingConfig.fromMap(map.getMap('naming_conventions'));

        // Check custom string value
        expect(config.getRuleFor(ArchComponent.model)?.pattern, '{{name}}Dto');

        // Check custom map value
        final entityRule = config.getRuleFor(ArchComponent.entity);
        expect(entityRule?.pattern, '{{name}}Object');
        expect(entityRule?.antipattern, '{{name}}Entity');

        // Check custom grammar value
        final useCaseRule = config.getRuleFor(ArchComponent.usecase);
        expect(useCaseRule?.grammar, '{{verb}}{{noun}}Action');
        // It should have fallen back to the default pattern.
        expect(useCaseRule?.pattern, '{{name}}');
      });

      test('should use all default values when map is empty', () {
        final map = <String, dynamic>{};
        final config = NamingConfig.fromMap(map);

        expect(config.getRuleFor(ArchComponent.model)?.pattern, '{{name}}Model');
        expect(config.getRuleFor(ArchComponent.contract)?.pattern, '{{name}}Repository');
        expect(config.getRuleFor(ArchComponent.entity)?.antipattern, isNull);
        expect(config.getRuleFor(ArchComponent.usecase)?.grammar, isNull);
      });
    });
  });
}
