import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/handlers/conditional_handler.dart';
import 'package:architecture_lints/src/actions/context/handlers/list_handler.dart';
import 'package:architecture_lints/src/actions/context/handlers/map_handler.dart';
import 'package:architecture_lints/src/actions/context/handlers/set_handler.dart';
import 'package:architecture_lints/src/actions/context/helpers/import_extractor.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/config/enums/variable_type.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockExpressionEngine extends Mock implements ExpressionEngine {}

class MockVariableResolver extends Mock implements VariableResolver {}

// 1. Define a Fake for VariableConfig
class FakeVariableConfig extends Fake implements VariableConfig {}

void main() {
  late MockExpressionEngine mockEngine;
  late MockVariableResolver mockResolver;

  // Dummy context
  final context = <String, dynamic>{'val': 10};

  setUpAll(() {
    // 2. Register the fallback value
    registerFallbackValue(FakeVariableConfig());
  });

  setUp(() {
    mockEngine = MockExpressionEngine();
    mockResolver = MockVariableResolver();

    // Default eval behavior: return the string itself or specific values
    when(() => mockEngine.evaluate(any(), any())).thenAnswer((i) {
      final expr = i.positionalArguments[0] as String;
      if (expr == 'true') return true;
      if (expr == 'false') return false;
      return expr; // Return raw string for others
    });
  });

  group('ConditionalHandler', () {
    late ConditionalHandler handler;

    setUp(() {
      handler = ConditionalHandler(mockEngine);
    });

    test('should return result when condition is true', () {
      final select = [
        const VariableSelect(
          condition: 'false',
          result: VariableConfig(type: VariableType.string, value: 'A'),
        ),
        const VariableSelect(
          condition: 'true',
          result: VariableConfig(type: VariableType.string, value: 'B'),
        ),
      ];

      final result = handler.handle(select, context);
      expect(result?.value, 'B');
    });

    test('should return else result', () {
      final select = [
        const VariableSelect(
          condition: 'false',
          result: VariableConfig(type: VariableType.string, value: 'A'),
        ),
        const VariableSelect(
          condition: null,
          result: VariableConfig(type: VariableType.string, value: 'Else'),
        ),
      ];

      final result = handler.handle(select, context);
      expect(result?.value, 'Else');
    });
  });

  group('ListVariableHandler', () {
    late ListHandler handler;

    setUp(() {
      handler = ListHandler(mockEngine);
    });

    test('should transform list from source', () {
      // Mock engine to return a list for 'source.items'
      when(() => mockEngine.evaluate('source.items', any())).thenReturn(['A', 'B']);

      // Mock resolver to handle the schema
      // Now safe because FakeVariableConfig is registered
      when(() => mockResolver.resolveConfig(any(), any())).thenAnswer((i) {
        // Return item + '_processed'
        final ctx = i.positionalArguments[1] as Map;
        return '${ctx['item']}_processed';
      });

      const config = VariableConfig(
        type: VariableType.list,
        from: 'source.items',
        mapSchema: {'name': VariableConfig(type: VariableType.string, value: 'ignored_by_mock')},
      );

      final result = handler.handle(config, context, mockResolver);

      expect(result['items'], isA<List>());
      final list = result['items'] as List;
      expect(list.length, 2);
      expect(list[0]['name'], 'A_processed');
      expect(list[1]['name'], 'B_processed');
      expect(result['length'], 2);
    });

    test('should handle explicit values', () {
      const config = VariableConfig(
        type: VariableType.list,
        values: ['"X"', '"Y"'],
      );

      final result = handler.handle(config, context, mockResolver);

      final list = result['items'] as List;
      expect(list, ['"X"', '"Y"']); // Engine returns raw string per setup
    });
  });

  group('SetVariableHandler', () {
    late SetHandler handler;

    setUp(() {
      handler = SetHandler(mockEngine, const ImportExtractor('test_pkg'));
    });

    test('should flatten and sort unique imports', () {
      const config = VariableConfig(
        type: VariableType.set,
        values: [
          'package:b/b.dart',
          'package:a/a.dart',
          'package:b/b.dart', // Duplicate
        ],
      );

      final result = handler.handle(config, context, mockResolver);

      final list = result['items'] as List;
      expect(list, ['package:a/a.dart', 'package:b/b.dart']);
      expect(result['length'], 2);
    });

    test('should convert file paths to package URIs', () {
      const config = VariableConfig(
        type: VariableType.set,
        values: [
          '/User/project/lib/feature/file.dart',
        ],
      );

      final result = handler.handle(config, context, mockResolver);

      final list = result['items'] as List;
      // ImportExtractor logic check
      expect(list.first, 'package:test_pkg/feature/file.dart');
    });
  });

  group('MapVariableHandler', () {
    late MapHandler handler;

    setUp(() {
      handler = MapHandler(mockEngine);
    });

    test('should merge spread maps', () {
      when(() => mockEngine.evaluate('map1', any())).thenReturn({'a': 1});
      when(() => mockEngine.evaluate('map2', any())).thenReturn({'b': 2});

      const config = VariableConfig(
        type: VariableType.map,
        spread: ['map1', 'map2'],
      );

      final result = handler.handle(config, context, mockResolver);

      expect(result, {'a': 1, 'b': 2});
    });
  });
}
