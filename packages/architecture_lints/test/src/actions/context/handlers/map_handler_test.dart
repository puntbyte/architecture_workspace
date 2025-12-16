import 'package:architecture_lints/src/engines/expression/expression_engine.dart';
import 'package:architecture_lints/src/engines/variable/handlers/map_handler.dart';
import 'package:architecture_lints/src/engines/variable/variable_resolver.dart';
import 'package:architecture_lints/src/schema/enums/variable_type.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/variable_definition.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

void main() {
  group('MapHandler', () {
    late MapHandler handler;
    late VariableResolver resolver;

    setUp(() async {
      final unit = await resolveContent('class A {}');
      final node = unit.unit.declarations.first;
      final config = ArchitectureConfig.empty();
      final engine = ExpressionEngine(node: node, config: config);

      handler = MapHandler(engine);
      resolver = VariableResolver(sourceNode: node, config: config, packageName: 'test');
    });

    test('should handle explicit value map', () {
      const config = VariableDefinition(
        type: VariableType.map,
        // The value property in config is a string expression.
        // We simulate an expression that returns a Map.
        value: 'myMap',
      );

      final context = {
        'myMap': {'key': 'value'},
      };

      final result = handler.handle(config, context, resolver) as Map;
      expect(result['key'], 'value');
    });

    test('should merge maps via spread', () {
      const config = VariableDefinition(
        type: VariableType.map,
        spread: ['map1', 'map2'],
      );

      final context = {
        'map1': {'a': 1, 'b': 2},
        'map2': {'b': 99, 'c': 3}, // 'b' overrides map1
      };

      final result = handler.handle(config, context, resolver) as Map;

      expect(result['a'], 1);
      expect(result['b'], 99); // Last one wins
      expect(result['c'], 3);
    });
  });
}
