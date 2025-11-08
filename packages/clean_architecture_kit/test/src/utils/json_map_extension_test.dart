// test/src/utils/extensions/json_map_extension_test.dart

import 'package:clean_architecture_kit/src/utils/json_map_extension.dart';
import 'package:test/test.dart';

void main() {
  group('JsonMapExtension', () {
    // --- getMap ---
    group('getMap', () {
      test('should return map when value is a valid map', () {
        final source = {'config': {'key': 'value'}};
        expect(source.getMap('config'), {'key': 'value'});
      });

      test('should return empty map when key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getMap('config'), isEmpty);
      });

      test('should return empty map when value is not a map', () {
        final source = {'config': 'not_a_map'};
        expect(source.getMap('config'), isEmpty);
      });

      test('should return empty map when value is null', () {
        final source = <String, dynamic>{'config': null};
        expect(source.getMap('config'), isEmpty);
      });
    });

    // --- getList ---
    group('getList', () {
      test('should return list of strings when value is a valid list', () {
        final source = {'items': ['a', 'b']};
        expect(source.getList('items'), ['a', 'b']);
      });

      test('should return default empty list when key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getList('items'), isEmpty);
      });

      test('should return provided orElse list when key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getList('items', ['default']), ['default']);
      });

      test('should return orElse list when value is not a list', () {
        final source = {'items': 'not_a_list'};
        expect(source.getList('items', ['default']), ['default']);
      });

      test('should return orElse list for a mixed-type list (strict check)', () {
        final source = {'items': ['a', 123, 'b']};
        expect(source.getList('items', ['default']), ['default']);
      });
    });

    // --- getString ---
    group('getString', () {
      test('should return string value when it exists', () {
        final source = {'name': 'my_app'};
        expect(source.getString('name'), 'my_app');
      });

      test('should return orElse value when key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getString('name', 'default'), 'default');
      });

      test('should return orElse value when value is not a string', () {
        final source = {'name': 123};
        expect(source.getString('name', 'default'), 'default');
      });

      test('should return default empty string if orElse is not provided', () {
        final source = {'name': 123};
        expect(source.getString('name'), '');
      });
    });

    // --- getOptionalString ---
    group('getOptionalString', () {
      test('should return string value when it exists', () {
        final source = {'path': '/lib/core'};
        expect(source.getOptionalString('path'), '/lib/core');
      });

      test('should return null when key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getOptionalString('path'), isNull);
      });

      test('should return null when value is not a string', () {
        final source = {'path': 123};
        expect(source.getOptionalString('path'), isNull);
      });

      test('should return null when value is explicitly null', () {
        final source = <String, dynamic>{'path': null};
        expect(source.getOptionalString('path'), isNull);
      });
    });
  });
}
