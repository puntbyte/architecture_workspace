// test/src/config/schema/component_config_test.dart

import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/schema/definitions/module_definition.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentConfig', () {
    group('fromMap', () {
      test('should parse fields', () {
        final map = {'path': 'lib', 'pattern': '{{name}}', 'default': true};
        final config = ComponentDefinition.fromMap('id', map);
        expect(config.id, 'id');
        expect(config.paths, ['lib']);
        expect(config.isDefault, isTrue);
      });
    });

    group('parseMap (Hierarchy Integration)', () {
      test('should flatten hierarchy', () {
        final yaml = {
          '.domain': {
            'path': 'domain',
            '.entity': {'pattern': '{{name}}'},
          },
        };
        final results = ComponentDefinition.parseMap(yaml, []);

        final domain = results.firstWhere((c) => c.id == 'domain');
        final entity = results.firstWhere((c) => c.id == 'domain.entity');

        expect(domain.paths, ['domain']);
        expect(entity.patterns, ['{{name}}']);
      });

      test('should inherit path from parent (Parent Inheritance)', () {
        final yaml = {
          '.source': {
            'path': 'data/sources',

            // Child missing path, should get 'data/sources'
            '.interface': {'pattern': 'I{{name}}'},

            // Child overrides path
            '.impl': {'path': 'data/sources/impl', 'pattern': '{{name}}Impl'},
          },
        };

        final results = ComponentDefinition.parseMap(yaml, []);

        final interface = results.firstWhere((c) => c.id == 'source.interface');
        expect(interface.paths, ['data/sources']);

        final impl = results.firstWhere((c) => c.id == 'source.impl');
        expect(impl.paths, ['data/sources/impl']);
      });

      test('should handle module scoping', () {
        final modules = [const ModuleDefinition(key: 'core', path: 'core')];
        final yaml = {
          'core': {
            '.util': {'path': 'utils'},
          },
        };

        final results = ComponentDefinition.parseMap(yaml, modules);

        expect(results.any((c) => c.id == 'core.util'), isTrue);
      });
    });
  });
}
