import 'package:architecture_lints/src/engines/expression/expression_resolver.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/generic_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/type_wrapper.dart';
import 'package:expressions/expressions.dart';
import 'package:test/test.dart';

void main() {
  group('GenericWrapper', () {
    late ExpressionEvaluator evaluator;

    setUp(() {
      evaluator = ExpressionResolver.evaluator();
    });

    test('should access structural properties', () {
      final generic = GenericWrapper(
        const StringWrapper('Map'),
        ListWrapper([
          TypeWrapper(null, rawString: 'String'),
          TypeWrapper(null, rawString: 'int'),
        ]),
      );

      final context = {'g': generic};

      expect(evaluator.eval(Expression.parse('g.base.value'), context), 'Map');
      expect(evaluator.eval(Expression.parse('g.length'), context), 2);

      expect(evaluator.eval(Expression.parse('g.first.name.value'), context), 'String');
      expect(evaluator.eval(Expression.parse('g.last.name.value'), context), 'int');
    });
  });
}
