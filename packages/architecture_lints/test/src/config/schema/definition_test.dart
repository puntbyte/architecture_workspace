import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:test/test.dart';

void main() {
  group('Definition', () {
    group('fromDynamic', () {
      test('should parse shorthand string', () {
        final def = Definition.fromDynamic('MyClass');
        expect(def.types, ['MyClass']);
        expect(def.type, 'MyClass');
        expect(def.isWildcard, isFalse);
      });

      test('should parse wildcard', () {
        final def = Definition.fromDynamic('*');
        expect(def.isWildcard, isTrue);
      });

      test('should parse map with single type and import', () {
        // Use Map<String, dynamic> for type safety
        final map = <String, dynamic>{'type': 'Future', 'import': 'dart:async'};
        final def = Definition.fromDynamic(map);
        expect(def.types, ['Future']);
        expect(def.imports, ['dart:async']);
      });

      test('should parse map with list of types', () {
        final map = <String, dynamic>{
          'type': ['GetIt', 'Injector'],
          'import': 'package:get_it/get_it.dart'
        };
        final def = Definition.fromDynamic(map);
        expect(def.types, ['GetIt', 'Injector']);
        expect(def.imports, ['package:get_it/get_it.dart']);
      });

      test('should parse identifiers list', () {
        // Use the exact key from ConfigKeys to ensure correctness
        final map = <String, dynamic>{
          ConfigKeys.definition.identifier: ['sl', 'getIt'],
        };

        final def = Definition.fromDynamic(map);
        expect(def.identifiers, ['sl', 'getIt']);
      });

      test('should parse rewrites list', () {
        final map = <String, dynamic>{
          'type': 'Either',
          'import': 'package:fpdart/fpdart.dart',
          ConfigKeys.definition.rewrite: ['package:fpdart/src/either.dart'],
        };
        final def = Definition.fromDynamic(map);
        expect(def.rewrites, ['package:fpdart/src/either.dart']);
      });

      test('should parse recursive arguments', () {
        final map = <String, dynamic>{
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
        final yaml = <String, dynamic>{
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
        final yaml = <String, dynamic>{
          'result': {
            '.success': {'type': 'Right', 'import': 'package:fpdart'},
            '.failure': {
              'type': 'Left',
            },
          },
        };

        final registry = Definition.parseRegistry(yaml);

        expect(registry['result.success']?.import, 'package:fpdart');
        expect(registry['result.failure']?.import, 'package:fpdart');
      });

      test('should override cascaded import', () {
        final yaml = <String, dynamic>{
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