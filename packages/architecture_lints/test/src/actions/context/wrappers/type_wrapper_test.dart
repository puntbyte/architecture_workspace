import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/wrappers/generic_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:expressions/expressions.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

void main() {
  group('TypeWrapper', () {
    late ExpressionEvaluator evaluator;

    setUp(() {
      evaluator = ExpressionEngine.evaluator();
    });

    Future<TypeWrapper> getType(String code, String className) async {
      final unit = await resolveContent(code);
      final clazz = unit.unit.declarations.whereType<ClassDeclaration>().firstWhere(
            (c) => c.name.lexeme == className,
      );
      final field = clazz.members.whereType<FieldDeclaration>().first;
      final type = field.fields.type!.type;
      return TypeWrapper(type);
    }

    dynamic eval(dynamic object, String prop) {
      return evaluator.eval(Expression.parse('obj.$prop'), {'obj': object});
    }

    test('should return raw name', () async {
      final wrapper = await getType('class A { String x; }', 'A');
      final name = eval(wrapper, 'name');
      expect(name, isA<StringWrapper>());
      expect(name.toString(), 'String');
    });

    test('should unwrap Future recursively', () async {
      final wrapper = await getType('class A { Future<List<int>> x; }', 'A');

      // Future -> List<int> (List is a collection, unwrapping stops)
      final unwrapped = eval(wrapper, 'unwrapped');
      expect(unwrapped.toString(), 'List<int>');
    });

    test('should unwrap FutureEither (Typedef)', () async {
      const code = '''
        class Future<T> {}
        class Either<L, R> {}
        typedef FutureEither<T> = Future<Either<String, T>>;
        class A { FutureEither<int> x; }
      ''';
      final wrapper = await getType(code, 'A');

      expect(eval(wrapper, 'name').toString(), 'FutureEither<int>');
      // Future -> Either -> int
      expect(eval(wrapper, 'unwrapped').toString(), 'int');
    });

    test('should expose generics structure', () async {
      final wrapper = await getType('class A { Map<String, int> x; }', 'A');

      final generics = eval(wrapper, 'generics');
      expect(generics, isA<GenericWrapper>());

      expect(evaluator.eval(Expression.parse('g.base.value'), {'g': generics}), 'Map');
      expect(evaluator.eval(Expression.parse('g.length'), {'g': generics}), 2);
    });

    test('should identify isFuture', () async {
      final f = await getType('class A { Future<void> x; }', 'A');
      expect(eval(f, 'isFuture'), true);

      final s = await getType('class A { String x; }', 'A');
      expect(eval(s, 'isFuture'), false);
    });
  });
}