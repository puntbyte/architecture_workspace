// test/src/config/schema/definition_test.dart

import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:test/test.dart';

void main() {
  group('Definition', () {
    group('fromDynamic', () {
      test('should parse shorthand string', () {
        final def = Definition.fromDynamic('MyClass');
        expect(def.type, 'MyClass');
        expect(def.isWildcard, isFalse);
      });

      test('should parse wildcard', () {
        final def = Definition.fromDynamic('*');
        expect(def.isWildcard, isTrue);
      });

      test('should parse map', () {
        final map = {'type': 'Future', 'import': 'pkg/async'};
        final def = Definition.fromDynamic(map);
        expect(def.type, 'Future');
        expect(def.import, 'pkg/async');
      });

      test('should parse identifiers list', () {
        final def = Definition.fromDynamic(const {
          'identifiers': ['sl', 'getIt'],
        });
        expect(def.identifiers, ['sl', 'getIt']);
      });

      test('should parse recursive arguments', () {
        final map = {
          'type': 'Either',
          'argument': [
            {'type': 'L'},
            {'type': 'R'},
          ],
        };
        final def = Definition.fromDynamic(map);
        expect(def.arguments, hasLength(2));
        expect(def.arguments[0].type, 'L');
        expect(def.arguments[1].type, 'R');
      });
    });

    group('parseRegistry (Hierarchy Integration)', () {
      test('should parse nested keys with dots', () {
        final yaml = {
          'domain': {
            '.base': {'type': 'Entity'},
            '.sub': {'type': 'SubEntity'},
          },
        };

        final registry = Definition.parseRegistry(yaml);

        expect(registry.keys, containsAll(['domain.base', 'domain.sub']));
        expect(registry['domain.base']?.type, 'Entity');
      });

      test('should cascade imports (Sibling Inheritance)', () {
        final yaml = {
          'result': {
            // First item defines import
            '.success': {'type': 'Right', 'import': 'package:fpdart'},
            // Second item should inherit 'package:fpdart' via HierarchyParser
            '.failure': {
              'type': 'Left',
              // missing import
            },
          },
        };

        final registry = Definition.parseRegistry(yaml);

        expect(registry['result.success']?.import, 'package:fpdart');
        expect(registry['result.failure']?.import, 'package:fpdart');
      });

      test('should override cascaded import', () {
        final yaml = {
          'group': {
            '.first': {'type': 'A', 'import': 'pkg/a'},
            '.second': {'type': 'B', 'import': 'pkg/b'},
          },
        };

        final registry = Definition.parseRegistry(yaml);

        expect(registry['group.first']?.import, 'pkg/a');
        expect(registry['group.second']?.import, 'pkg/b');
      });
    });
  });
}
