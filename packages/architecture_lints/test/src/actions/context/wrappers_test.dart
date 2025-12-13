import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/wrappers/generic_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/method_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/parameter_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:test/test.dart';

import '../../../helpers/test_resolver.dart';

void main() {
  group('StringWrapper', () {
    test('should handle concatenation', () {
      const wrapper = StringWrapper('Hello');
      final result1 = wrapper + ' World';
      expect(result1, isA<String>());
      expect(result1, 'Hello World');
    });
  });

  group('TypeWrapper', () {
    Future<TypeWrapper> getType(String code, String className) async {
      final unit = await resolveContent(code);
      final clazz = unit.unit.declarations.whereType<ClassDeclaration>().firstWhere(
        (c) => c.name.lexeme == className,
      );
      final field = clazz.members.whereType<FieldDeclaration>().first;
      final type = field.fields.type!.type;
      return TypeWrapper(type);
    }

    test('should return raw name', () async {
      final wrapper = await getType('class A { String x; }', 'A');
      expect(wrapper.name.value, 'String');
    });

    test('should expose generics structure', () async {
      final wrapper = await getType('class A { Map<String, int> x; }', 'A');

      final generics = wrapper.generics;
      expect(generics, isNotNull);
      expect(generics, isA<GenericWrapper>());

      expect(generics!.base.value, 'Map');
      expect(generics.length, 2);
      expect(generics.first?.name.value, 'String');
      expect(generics.last?.name.value, 'int');
    });

    test('should unwrap FutureEither (Typedef)', () async {
      const code = '''
        class Future<T> {}
        class Either<L, R> {}
        typedef FutureEither<T> = Future<Either<String, T>>;
        class A { FutureEither<int> x; }
      ''';
      final wrapper = await getType(code, 'A');

      expect(wrapper.name.value, 'FutureEither<int>');
      // unwrapped should dig deep
      expect(wrapper.unwrapped.value, 'int');
    });
  });

  group('NodeWrappers', () {
    Future<MethodWrapper> getMethod(String code) async {
      final unit = await resolveContent(code);
      final clazz = unit.unit.declarations.whereType<ClassDeclaration>().first;
      final method = clazz.members.whereType<MethodDeclaration>().first;
      return MethodWrapper(method);
    }

    test('MethodWrapper should wrap return type and parameters', () async {
      const code = '''
        class UseCase {
          Future<void> call(String id, {required int count}) {}
        }
      ''';
      final method = await getMethod(code);
      expect(method.name.value, 'call');
      expect(method.returnType.toString(), 'Future<void>');
      expect(method.parameters.length, 2);
      expect(method.parameters[0], isA<ParameterWrapper>());
    });

    test('ParameterWrapper should expose properties', () async {
      const code = 'class A { void f(String p1, {required int p2}) {} }';
      final method = await getMethod(code);
      final p1 = method.parameters[0];

      expect(p1.name.value, 'p1');
      expect(p1.isPositional, true);

      final p2 = method.parameters[1];
      expect(p2.isNamed, true);
      expect(p2.isRequired, true);
    });
  });
}
