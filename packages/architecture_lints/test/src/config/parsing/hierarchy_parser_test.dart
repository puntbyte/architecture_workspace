// test/hierarchy_parser_test.dart
import 'package:architecture_lints/src/config/parsing/hierarchy_parser.dart';
import 'package:test/test.dart';

void main() {
  // Helper factory that wraps the id and effective node into a Map so tests can inspect them.
  Map<String, dynamic> probeFactory(String id, dynamic node) {
    return {'id': id, 'node': node};
  }

  group('HierarchyParser', () {
    test('shorthand expansion: string node expands to map using shorthandKey', () {
      final yaml = <String, dynamic>{
        'a': 'hello', // primitive string at top-level
      };

      final results = HierarchyParser.parse<Map<String, dynamic>>(
        yaml: yaml,
        factory: probeFactory,
        shorthandKey: 'value',
      );

      // top-level key 'a' becomes a node
      expect(results.containsKey('a'), isTrue);
      final entry = results['a']!;
      expect(entry['id'], 'a');

      // the factory should have received a map: { value: 'hello' }
      expect(entry['node'], isA<Map>());
      final node = entry['node'] as Map;
      expect(node['value'], 'hello');
    });

    test('inheritProperties: parent property flows down to child', () {
      final yaml = <String, dynamic>{
        'parent': <String, dynamic>{
          'lang': 'fr',
          '.child': <String, dynamic>{'name': 'c'},
        }
      };

      final results = HierarchyParser.parse<Map<String, dynamic>>(
        yaml: yaml,
        factory: probeFactory,
        inheritProperties: ['lang'],
      );

      // parent was parsed
      expect(results.containsKey('parent'), isTrue);
      expect(results['parent']!['id'], 'parent');

      // child id should be parent.child and its effective node should include the inherited 'lang'
      expect(results.containsKey('parent.child'), isTrue);
      final childEntry = results['parent.child']!;
      expect(childEntry['id'], 'parent.child');

      // Node should be a Map that contains 'name' and inherited 'lang'
      expect(childEntry['node'], isA<Map>());
      final childNode = childEntry['node'] as Map;
      expect(childNode['name'], 'c');
      expect(childNode['lang'], 'fr'); // inherited
    });

    test('cascadeProperties: property set on first sibling cascades to next sibling', () {
      final yaml = <String, dynamic>{
        'root': <String, dynamic>{
          '.first': <String, dynamic>{'color': 'red'},
          '.second': <String, dynamic>{}, // should receive color via cascade
        }
      };

      final results = HierarchyParser.parse<Map<String, dynamic>>(
        yaml: yaml,
        factory: probeFactory,
        cascadeProperties: ['color'],
      );

      // both siblings parsed
      expect(results.containsKey('root.first'), isTrue);
      expect(results.containsKey('root.second'), isTrue);

      // first keeps its color
      final firstNode = results['root.first']!['node'] as Map;
      expect(firstNode['color'], 'red');

      // second should have received the cascaded color from first
      final secondNode = results['root.second']!['node'] as Map;
      expect(secondNode['color'], 'red');
    });

    test('scopeKeys: only keys in scope are parsed at root when scopeKeys provided', () {
      final yaml = <String, dynamic>{
        'a': <String, dynamic>{},
        'b': <String, dynamic>{},
      };

      final results = HierarchyParser.parse<Map<String, dynamic>>(
        yaml: yaml,
        factory: probeFactory,
        scopeKeys: {'a'}, // only 'a' should be parsed
      );

      expect(results.containsKey('a'), isTrue);
      expect(results.containsKey('b'), isFalse);
    });

    test('shouldParseNode: predicate can skip nodes', () {
      final yaml = <String, dynamic>{
        'a': <String, dynamic>{'enabled': false},
        'b': <String, dynamic>{'enabled': true},
      };

      final results = HierarchyParser.parse<Map<String, dynamic>>(
        yaml: yaml,
        factory: probeFactory,
        shouldParseNode: (value) {
          // value here is the effective node; we expect it to be a Map
          if (value is Map && value.containsKey('enabled')) {
            return value['enabled'] == true;
          }
          return false;
        },
      );

      expect(results.containsKey('a'), isFalse, reason: 'node a should be skipped by predicate');
      expect(results.containsKey('b'), isTrue, reason: 'node b should be parsed');
    });

    test('onError is called when factory throws for a node without affecting others', () {
      final yaml = <String, dynamic>{
        'good': <String, dynamic>{'x': 1},
        'bad': <String, dynamic>{'x': 2},
        'also_good': <String, dynamic>{'x': 3},
      };

      final called = <Object>[];
      final stackTraces = <StackTrace>[];

      Map<String, dynamic> throwingFactory(String id, dynamic node) {
        if (id == 'bad') {
          throw Exception('factory failed for $id');
        }
        return {'id': id, 'x': (node is Map ? node['x'] : null)};
      }

      final results = HierarchyParser.parse<Map<String, dynamic>>(
        yaml: yaml,
        factory: throwingFactory,
        onError: (err, st) {
          called.add(err);
          stackTraces.add(st);
        },
      );

      // 'good' and 'also_good' should be present
      expect(results.containsKey('good'), isTrue);
      expect(results.containsKey('also_good'), isTrue);

      // 'bad' should be missing (factory threw and was handled by onError)
      expect(results.containsKey('bad'), isFalse);

      // onError should have been called exactly once with an Exception mentioning 'bad'
      expect(called, hasLength(1));
      expect(called.first.toString(), contains('factory failed for bad'));
      expect(stackTraces, hasLength(1));
    });
  });
}
