// test/src/utils/map_extensions_test.dart

import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('MapExtensions', () {
    // --- Primitives ---

    group('getString', () {
      test('should return the string value when key exists and is a String', () {
        final map = {'key': 'value'};
        expect(map.getString('key'), 'value');
      });

      test('should return empty string by default when key is missing', () {
        final map = {'other': 'value'};
        expect(map.getString('missing_key'), '');
      });

      test('should return provided fallback when key is missing', () {
        final map = {'other': 'value'};
        expect(map.getString('missing_key', fallback: 'default'), 'default');
      });

      test('should return fallback when value is not a String', () {
        final map = {'key': 123}; // Integer value
        expect(map.getString('key', fallback: 'default'), 'default');
      });
    });

    group('tryGetString', () {
      test('should return the string value when key exists', () {
        final map = {'key': 'value'};
        expect(map.tryGetString('key'), 'value');
      });

      test('should return null by default when key is missing', () {
        final map = {'other': 'value'};
        expect(map.tryGetString('missing_key'), isNull);
      });

      test('should return fallback when key is missing', () {
        final map = {'other': 'value'};
        expect(map.tryGetString('missing_key', fallback: 'fb'), 'fb');
      });

      test('should return null when value is wrong type', () {
        final map = {'key': true};
        expect(map.tryGetString('key'), isNull);
      });
    });

    group('getBool', () {
      test('should return true when value is true', () {
        final map = {'flag': true};
        expect(map.getBool('flag'), isTrue);
      });

      test('should return false when value is false', () {
        final map = {'flag': false};
        expect(map.getBool('flag'), isFalse);
      });

      test('should return false by default when key is missing', () {
        final map = {};
        expect(map.getBool('flag'), isFalse);
      });

      test('should return provided fallback when key is missing', () {
        final map = {};
        expect(map.getBool('flag', fallback: true), isTrue);
      });

      test('should return fallback when value is not a boolean', () {
        final map = {'flag': 'true'}; // String "true", not boolean true
        expect(map.getBool('flag', fallback: false), isFalse);
      });
    });

    // --- Collections ---

    group('getStringList', () {
      test('should return a list of strings when value is a List<String>', () {
        final map = {
          'items': ['a', 'b'],
        };
        expect(map.getStringList('items'), ['a', 'b']);
      });

      test('should return a list of strings when value is a List<dynamic>', () {
        final map = {
          'items': ['a', 'b'],
        };
        expect(map.getStringList('items'), ['a', 'b']);
      });

      test('should filter out non-string elements from mixed list', () {
        final map = {
          'items': ['a', 123, true, 'b'],
        };
        expect(map.getStringList('items'), ['a', 'b']);
      });

      test('should wrap a single string value into a list', () {
        // Common YAML pattern: items: "value" instead of items: ["value"]
        final map = {'items': 'single_value'};
        expect(map.getStringList('items'), ['single_value']);
      });

      test('should return empty list when key is missing', () {
        final map = {};
        expect(map.getStringList('items'), isEmpty);
      });

      test('should return empty list when value is not a list or string', () {
        final map = {'items': 123};
        expect(map.getStringList('items'), isEmpty);
      });
    });

    group('getMap', () {
      test('should return the map when value is a Map<String, dynamic>', () {
        final map = {
          'config': {'a': 1},
        };
        final result = map.getMap('config');
        expect(result, isA<Map<String, dynamic>>());
        expect(result['a'], 1);
      });

      test('should correctly cast Map<dynamic, dynamic> (Simulating YamlMap)', () {
        // This mimics exactly what loadYaml returns
        final dynamicMap = <dynamic, dynamic>{'a': 1, 'b': 'hello'};
        final map = {'config': dynamicMap};

        final result = map.getMap('config');

        expect(result, isA<Map<String, dynamic>>());
        expect(result['a'], 1);
        expect(result['b'], 'hello');
      });

      test('should return empty map when key is missing', () {
        final map = {};
        expect(map.getMap('config'), isEmpty);
      });

      test('should return empty map when value is not a Map', () {
        final map = {'config': 'not_a_map'};
        expect(map.getMap('config'), isEmpty);
      });

      test('should return empty map when keys in nested map are not strings', () {
        final invalidMap = <dynamic, dynamic>{1: 'integer_key'};
        final map = {'config': invalidMap};

        // Standard Map.from throws on invalid casts, our extension should catch it and return empty
        expect(map.getMap('config'), isEmpty);
      });
    });

    group('getMapList', () {
      test('should return List<Map<String, dynamic>> for valid input', () {
        final map = {
          'rules': [
            {'id': 'rule1', 'enabled': true},
            {'id': 'rule2'},
          ],
        };

        final result = map.getMapList('rules');
        expect(result, hasLength(2));
        expect(result[0]['id'], 'rule1');
        expect(result[1]['id'], 'rule2');
      });

      test('should ignore non-map items in the list', () {
        final map = {
          'rules': [
            {'id': 'valid'},
            'not_a_map', // string
            123, // int
            {'id': 'valid2'},
          ],
        };

        final result = map.getMapList('rules');
        expect(result, hasLength(2));
        expect(result[0]['id'], 'valid');
        expect(result[1]['id'], 'valid2');
      });

      test('should handle nested dynamic maps (Yaml behavior)', () {
        final map = {
          'rules': <dynamic>[
            <dynamic, dynamic>{'a': 1},
            <dynamic, dynamic>{'b': 2},
          ],
        };

        final result = map.getMapList('rules');
        expect(result[0], isA<Map<String, dynamic>>());
        expect(result[0]['a'], 1);
      });

      test('should return empty list if key is missing', () {
        final map = {};
        expect(map.getMapList('missing'), isEmpty);
      });

      test('should return empty list if value is not a list', () {
        final map = {'rules': 'not_list'};
        expect(map.getMapList('rules'), isEmpty);
      });
    });

    group('getMapMap', () {
      test('should return Map<String, Map<String, dynamic>> for valid input', () {
        // e.g., components: { domain: { path: '...' }, data: { path: '...' } }
        final map = {
          'components': {
            'domain': {'path': 'lib/domain'},
            'data': {'path': 'lib/data'},
          },
        };

        final result = map.getMapMap('components');
        expect(result, hasLength(2));
        expect(result['domain']?['path'], 'lib/domain');
        expect(result['data']?['path'], 'lib/data');
      });

      test('should ignore entries where value is not a Map', () {
        final map = {
          'components': {
            'valid': {'a': 1},
            'invalid': 'just_a_string', // Should be skipped
            'invalid2': 123,
          },
        };

        final result = map.getMapMap('components');
        expect(result, hasLength(1));
        expect(result.containsKey('valid'), isTrue);
        expect(result.containsKey('invalid'), isFalse);
      });

      test('should ignore entries where key is not a String', () {
        final map = {
          'components': {
            'valid': {'a': 1},
            123: {'a': 2}, // Integer key, should be skipped
          },
        };

        final result = map.getMapMap('components');
        expect(result, hasLength(1));
        expect(result.containsKey('valid'), isTrue);
      });

      test('should handle dynamic map inputs correctly', () {
        final nested = <dynamic, dynamic>{
          'item1': <dynamic, dynamic>{'val': 1},
        };
        final map = {'config': nested};

        final result = map.getMapMap('config');
        expect(result['item1'], isA<Map<String, dynamic>>());
        expect(result['item1']!['val'], 1);
      });

      test('should return empty map if value is not a map', () {
        final map = {'config': 'string_value'};
        expect(map.getMapMap('config'), isEmpty);
      });

      test('should return empty map if key is missing', () {
        final map = {};
        expect(map.getMapMap('config'), isEmpty);
      });
    });
  });
}
