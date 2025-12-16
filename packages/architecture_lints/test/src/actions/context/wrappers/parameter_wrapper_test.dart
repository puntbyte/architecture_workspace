import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/engines/expression/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/wrappers/parameter_wrapper.dart';
import 'package:expressions/expressions.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

void main() {
  group('ParameterWrapper', () {
    late ExpressionEvaluator evaluator;

    setUp(() {
      evaluator = ExpressionEngine.evaluator();
    });

    Future<ParameterWrapper> getParam(String code, int index) async {
      final unit = await resolveContent(code);
      final clazz = unit.unit.declarations.whereType<ClassDeclaration>().first;
      final method = clazz.members.whereType<MethodDeclaration>().first;
      return ParameterWrapper(method.parameters!.parameters[index]);
    }

    test('should detect named and positional params', () async {
      const code = 'class A { void f(int a, {required String b}) {} }';

      final p1 = await getParam(code, 0);
      expect(evaluator.eval(Expression.parse('p.isPositional'), {'p': p1}), true);
      expect(evaluator.eval(Expression.parse('p.isNamed'), {'p': p1}), false);

      final p2 = await getParam(code, 1);
      expect(evaluator.eval(Expression.parse('p.isNamed'), {'p': p2}), true);
      expect(evaluator.eval(Expression.parse('p.isRequired'), {'p': p2}), true);
    });

    test('should access type info', () async {
      final p1 = await getParam('class A { void f(String x) {} }', 0);
      final typeName = evaluator.eval(Expression.parse('p.type.name.value'), {'p': p1});
      expect(typeName, 'String');
    });
  });
}