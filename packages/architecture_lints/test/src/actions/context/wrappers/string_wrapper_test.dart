import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:expressions/expressions.dart';
import 'package:test/test.dart';

void main() {
  group('StringWrapper', () {
    late ExpressionEvaluator evaluator;

    setUp(() {
      evaluator = ExpressionEngine.evaluator();
    });

    dynamic eval(dynamic object, String prop) {
      return evaluator.eval(Expression.parse('obj.$prop'), {'obj': object});
    }

    test('should return primitive Strings for casing properties', () {
      const wrapper = StringWrapper('user_data');

      expect(eval(wrapper, 'pascalCase'), 'UserData');
      expect(eval(wrapper, 'snakeCase'), 'user_data');
      expect(eval(wrapper, 'camelCase'), 'userData');
    });

    test('should handle boolean checks', () {
      const empty = StringWrapper('');
      expect(eval(empty, 'isEmpty'), true);
      expect(eval(empty, 'isNotEmpty'), false);

      const filled = StringWrapper('hello');
      expect(eval(filled, 'length'), 5);
    });

    test('should handle replace method via expression', () {
      const wrapper = StringWrapper('Hello World');
      final result = evaluator.eval(
        Expression.parse("obj.replace('World', 'Dart')"),
        {'obj': wrapper},
      );
      expect(result, 'Hello Dart');
    });

    test('should return value on toString', () {
      const wrapper = StringWrapper('Hello');
      expect(wrapper.toString(), 'Hello');
    });
  });
}