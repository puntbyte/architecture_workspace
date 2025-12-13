import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/wrappers/node_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:test/test.dart';

import '../../../helpers/test_resolver.dart';

void main() {
  group('ExpressionEngine', () {
    late AstNode sourceNode;
    late ArchitectureConfig config;
    late ExpressionEngine engine;

    setUp(() async {
      final unit = await resolveContent('class TestClass {}');
      sourceNode = unit.unit.declarations.first;
      config = ArchitectureConfig.empty();
      engine = ExpressionEngine(sourceNode: sourceNode, config: config);
    });

    test('should initialize rootContext with source and config', () {
      expect(engine.rootContext.containsKey('source'), isTrue);
      expect(engine.rootContext['source'], isA<NodeWrapper>());
      expect(engine.rootContext.containsKey('config'), isTrue);
    });

    test('should evaluate simple expressions', () {
      expect(engine.evaluate('1 + 1', {}), 2);
      expect(engine.evaluate("'hello' + ' world'", {}), 'hello world');
      expect(engine.evaluate('true && false', {}), false);
    });

    test('should evaluate expressions using root context', () {
      expect(engine.evaluate('source.name.value', {}), 'TestClass');
    });

    test('should evaluate expressions using passed context', () {
      final context = {'custom': 123};
      expect(engine.evaluate('custom + 1', context), 124);
    });

    test('should handle evaluation errors gracefully', () {
      // 1. Syntax Error -> Returns raw string (caught exception)
      expect(engine.evaluate('1 + ', {}), '1 + ');

      // 2. Unknown Variable -> Returns null (valid expression, evaluates to null)
      expect(engine.evaluate('unknown_var', {}), isNull);
    });

    group('unwrap', () {
      test('should unwrap StringWrapper', () {
        expect(engine.unwrap(const StringWrapper('test')), 'test');
      });

      test('should unwrap nested Lists', () {
        final input = [const StringWrapper('a'), const StringWrapper('b')];
        final output = engine.unwrap(input);
        expect(output, ['a', 'b']);
      });

      test('should unwrap nested Maps', () {
        final input = {
          'key': const StringWrapper('value'),
          'nested': [const StringWrapper('item')],
        };

        final output = engine.unwrap(input);

        expect(output['key'], 'value');
        expect(output['nested'], ['item']);
      });

      test('should pass through primitives', () {
        expect(engine.unwrap(123), 123);
        expect(engine.unwrap(12.5), 12.5);
        expect(engine.unwrap(true), true);
        expect(engine.unwrap('str'), 'str');
        expect(engine.unwrap(null), isNull);
      });
    });
  });
}
