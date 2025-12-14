import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:expressions/expressions.dart';
import 'package:test/test.dart';

void main() {
  group('ListWrapper', () {
    late ExpressionEvaluator evaluator;

    setUp(() {
      evaluator = ExpressionEngine.evaluator();
    });

    dynamic eval(dynamic object, String prop) {
      return evaluator.eval(Expression.parse('obj.$prop'), {'obj': object});
    }

    test('should handle empty list', () {
      const list = ListWrapper<String>([]);
      expect(eval(list, 'isEmpty'), true);
      expect(eval(list, 'isNotEmpty'), false);
      expect(eval(list, 'hasMany'), false);
      expect(eval(list, 'isSingle'), false);
    });

    test('should handle single item list', () {
      const list = ListWrapper(['A']);
      expect(eval(list, 'isSingle'), true);
      expect(eval(list, 'hasMany'), false);
      expect(eval(list, 'first'), 'A');
    });

    test('should handle multiple items', () {
      const list = ListWrapper(['A', 'B']);
      expect(eval(list, 'isSingle'), false);
      expect(eval(list, 'hasMany'), true);
      expect(eval(list, 'length'), 2);
      expect(eval(list, 'last'), 'B');
    });

    test('should handle at(index) method', () {
      const list = ListWrapper(['A', 'B']);

      expect(evaluator.eval(Expression.parse('obj.at(0)'), {'obj': list}), 'A');
      expect(evaluator.eval(Expression.parse('obj.at(1)'), {'obj': list}), 'B');
      expect(evaluator.eval(Expression.parse('obj.at(99)'), {'obj': list}), null);
    });
  });
}
