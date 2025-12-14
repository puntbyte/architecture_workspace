import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/method_wrapper.dart';
import 'package:expressions/expressions.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

void main() {
  group('MethodWrapper', () {
    late ExpressionEvaluator evaluator;

    setUp(() {
      evaluator = ExpressionEngine.evaluator();
    });

    Future<MethodWrapper> getMethod(String code) async {
      final unit = await resolveContent(code);
      final clazz = unit.unit.declarations.whereType<ClassDeclaration>().first;
      final method = clazz.members.whereType<MethodDeclaration>().first;
      return MethodWrapper(method);
    }

    test('should access returnType', () async {
      final method = await getMethod('class A { Future<void> doIt() {} }');

      final ret = evaluator.eval(Expression.parse('m.returnType.name.value'), {'m': method});
      expect(ret, 'Future<void>');
    });

    test('should access parameters list', () async {
      final method = await getMethod('class A { void f(int a, String b) {} }');

      final params = evaluator.eval(Expression.parse('m.parameters'), {'m': method});
      expect(params, isA<ListWrapper>());

      final len = evaluator.eval(Expression.parse('m.parameters.length'), {'m': method});
      expect(len, 2);
    });
  });
}