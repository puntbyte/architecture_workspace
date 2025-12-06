import 'package:architecture_lints/src/config/parsing/hierarchy_parser.dart';
import 'package:test/test.dart';

class TestItem {
  final String id;
  final dynamic data;
  TestItem(this.id, this.data);
  dynamic get(String key) => (data is Map) ? data[key] : null;
  @override
  String toString() => '$id: $data';
}

void main() {
  group('HierarchyParser', () {
    TestItem factory(String id, dynamic value) => TestItem(id, value);
    bool alwaysValid(dynamic v) => true;

    test('should support Parent Inheritance (inheritProperties)', () {
      final yaml = {
        '.parent': {
          'path': 'root', // Inherited property
          '.child1': {'val': 1}, // Should inherit 'root'
          '.child2': {'path': 'override'} // Should override
        }
      };

      final result = HierarchyParser.parse<TestItem>(
        yaml: yaml,
        factory: factory,
        shouldParseNode: alwaysValid,
        inheritProperties: ['path'],
      );

      expect(result['parent']?.get('path'), 'root');
      expect(result['parent.child1']?.get('path'), 'root');
      expect(result['parent.child2']?.get('path'), 'override');
    });

    test('should support Sibling Cascading (cascadeProperties)', () {
      final yaml = {
        '.group': {
          '.first': {
            'import': 'pkg/a', // Cascades
            'val': 1
          },
          '.second': {
            'val': 2
            // Should inherit 'pkg/a' from .first
          },
          '.third': {
            'import': 'pkg/b', // Overrides
            'val': 3
          },
          '.fourth': {
            'val': 4
            // Should inherit 'pkg/b' from .third
          }
        }
      };

      final result = HierarchyParser.parse<TestItem>(
        yaml: yaml,
        factory: factory,
        shouldParseNode: alwaysValid,
        cascadeProperties: ['import'],
      );

      expect(result['group.first']?.get('import'), 'pkg/a');
      expect(result['group.second']?.get('import'), 'pkg/a');
      expect(result['group.third']?.get('import'), 'pkg/b');
      expect(result['group.fourth']?.get('import'), 'pkg/b');
    });

    test('should combine Parent and Sibling inheritance', () {
      final yaml = {
        '.parent': {
          'path': 'root', // Parent Inherit

          '.childA': {
            'import': 'pkg/a' // Sibling Cascade
          },
          '.childB': {
            // Should have path='root' AND import='pkg/a'
          }
        }
      };

      final result = HierarchyParser.parse<TestItem>(
        yaml: yaml,
        factory: factory,
        shouldParseNode: alwaysValid,
        inheritProperties: ['path'],
        cascadeProperties: ['import'],
      );

      final childB = result['parent.childB']!;
      expect(childB.get('path'), 'root');
      expect(childB.get('import'), 'pkg/a');
    });

    test('should reset Sibling Context when entering new parent', () {
      final yaml = {
        '.group1': {
          '.item': {'import': 'pkg/1'}
        },
        '.group2': {
          '.item': {} // Should NOT inherit pkg/1 from group1
        }
      };

      final result = HierarchyParser.parse<TestItem>(
        yaml: yaml,
        factory: factory,
        shouldParseNode: alwaysValid,
        cascadeProperties: ['import'],
      );

      expect(result['group1.item']?.get('import'), 'pkg/1');
      expect(result['group2.item']?.get('import'), isNull);
    });
  });
}