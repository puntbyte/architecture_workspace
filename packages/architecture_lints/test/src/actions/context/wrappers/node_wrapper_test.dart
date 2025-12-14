import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/wrappers/node_wrapper.dart';
import 'package:expressions/expressions.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

void main() {
  group('NodeWrapper', () {
    late ExpressionEvaluator evaluator;

    setUp(() {
      evaluator = ExpressionEngine.evaluator();
    });

    test('should access basic properties', () async {
      final unit = await resolveContent('class MyClass {}');
      final clazz = unit.unit.declarations.first;
      final wrapper = NodeWrapper(clazz);

      final name = evaluator.eval(Expression.parse('n.name.value'), {'n': wrapper});
      expect(name, 'MyClass');

      final path = evaluator.eval(Expression.parse('n.file.path.value'), {'n': wrapper});
      expect(path, contains('test.dart'));
    });

    test('should traverse parent', () async {
      final unit = await resolveContent('class A { void m() {} }');
      final clazz = unit.unit.declarations.first as ClassDeclaration;
      final method = clazz.members.first;

      final methodWrapper = NodeWrapper(method);

      final parentName = evaluator.eval(
          Expression.parse('n.parent.name.value'),
          {'n': methodWrapper}
      );

      expect(parentName, 'A');
    });
  });
}