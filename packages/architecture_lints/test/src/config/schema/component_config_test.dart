import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentConfig', () {
    group('fromMap', () {
      test('should parse fields', () {
        final map = {
          'path': 'lib',
          'pattern': '{{name}}',
          'default': true
        };
        final config = ComponentConfig.fromMap('id', map);
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
            '.entity': {'pattern': '{{name}}'}
          }
        };
        final results = ComponentConfig.parseMap(yaml, []);

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
            '.interface': {
              'pattern': 'I{{name}}'
            },

            // Child overrides path
            '.impl': {
              'path': 'data/sources/impl',
              'pattern': '{{name}}Impl'
            }
          }
        };

        final results = ComponentConfig.parseMap(yaml, []);

        final interface = results.firstWhere((c) => c.id == 'source.interface');
        expect(interface.paths, ['data/sources']);

        final impl = results.firstWhere((c) => c.id == 'source.impl');
        expect(impl.paths, ['data/sources/impl']);
      });

      test('should handle module scoping', () {
        final modules = [const ModuleConfig(key: 'core', path: 'core')];
        final yaml = {
          'core': {
            '.util': {'path': 'utils'}
          }
        };

        final results = ComponentConfig.parseMap(yaml, modules);

        expect(results.any((c) => c.id == 'core.util'), isTrue);
      });
    });
  });
}