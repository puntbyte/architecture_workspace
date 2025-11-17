// test/src/utils/extensions/json_map_extension_test.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';
import 'package:test/test.dart';

void main() {
  group('JsonMapExtension', () {
    // --- getMap ---
    group('getMap', () {
      test('should return a map when the value is a valid Map<String, dynamic>', () {
        final source = {'config': {'key': 'value'}};
        expect(source.getMap('config'), {'key': 'value'});
      });

      test('should return a map when the value is a generic Map', () {
        final source = <String, dynamic>{'config': <dynamic, dynamic>{'key': 'value'}};
        expect(source.getMap('config'), {'key': 'value'});
      });

      test('should return an empty map when the key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getMap('config'), isEmpty);
      });

      test('should return an empty map when the value is not a map', () {
        final source = {'config': 'not_a_map'};
        expect(source.getMap('config'), isEmpty);
      });

      test('should return an empty map when the value is null', () {
        final source = <String, dynamic>{'config': null};
        expect(source.getMap('config'), isEmpty);
      });
    });

    // --- getList ---
    group('getList', () {
      test('should return a list of strings when the value is a valid list', () {
        final source = {'items': ['a', 'b']};
        expect(source.getList('items'), ['a', 'b']);
      });

      test('should return a list containing the string when the value is a single string', () {
        final source = {'items': 'a'};
        expect(source.getList('items'), ['a']);
      });

      test('should return the default empty list when the key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getList('items'), isEmpty);
      });

      test('should return the provided orElse list when the key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getList('items', orElse: ['default']), ['default']);
      });

      test('should return the orElse list when the value is not a list or string', () {
        final source = {'items': 123};
        expect(source.getList('items', orElse: ['default']), ['default']);
      });

      test('should return the orElse list for a list with non-string items', () {
        final source = {'items': ['a', 123, 'b']};
        expect(source.getList('items', orElse: ['default']), ['default']);
      });
    });

    // --- getString ---
    group('getString', () {
      test('should return the string value when it exists', () {
        final source = {'name': 'my_app'};
        expect(source.getString('name'), 'my_app');
      });

      test('should return the orElse value when the key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getString('name', orElse: 'default'), 'default');
      });

      test('should return the orElse value when the value is not a string', () {
        final source = {'name': 123};
        expect(source.getString('name', orElse: 'default'), 'default');
      });

      test('should return the default empty string if orElse is not provided', () {
        final source = {'name': 123};
        expect(source.getString('name'), '');
      });
    });

    // --- getOptionalString ---
    group('getOptionalString', () {
      test('should return the string value when it exists', () {
        final source = {'path': '/lib/core'};
        expect(source.getOptionalString('path'), '/lib/core');
      });

      test('should return null when the key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getOptionalString('path'), isNull);
      });

      test('should return null when the value is not a string', () {
        final source = {'path': 123};
        expect(source.getOptionalString('path'), isNull);
      });

      test('should return null when the value is explicitly null', () {
        final source = <String, dynamic>{'path': null};
        expect(source.getOptionalString('path'), isNull);
      });
    });

    // --- getBool ---
    group('getBool', () {
      test('should return true when the value is true', () {
        final source = {'enabled': true};
        expect(source.getBool('enabled'), isTrue);
      });

      test('should return false when the value is false', () {
        final source = {'enabled': false};
        expect(source.getBool('enabled'), isFalse);
      });

      test('should return the default false when the key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getBool('enabled'), isFalse);
      });

      test('should return the provided orElse value when the key does not exist', () {
        final source = {'other': 'value'};
        expect(source.getBool('enabled', orElse: true), isTrue);
      });

      test('should return the orElse value when the value is not a boolean', () {
        final source = {'enabled': 'not_a_bool'};
        expect(source.getBool('enabled', orElse: true), isTrue);
      });

      test('should return the default false when the value is null', () {
        final source = <String, dynamic>{'enabled': null};
        expect(source.getBool('enabled'), isFalse);
      });
    });
  });
}
