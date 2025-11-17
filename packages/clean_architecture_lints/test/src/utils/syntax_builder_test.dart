// test/src/utils/syntax_builder_test.dart

import 'package:clean_architecture_lints/src/utils/syntax_builder.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

void main() {
  group('SyntaxBuilder', () {
    final emitter = cb.DartEmitter(useNullSafetySyntax: true);
    final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

    // A robust helper to format a spec and compare it to an expected string.
    void expectSpec(cb.Spec spec, String expected) {
      final actualSource = spec.accept(emitter).toString();
      // Format both the actual and expected source to ignore minor whitespace differences.
      expect(formatter.format(actualSource), equals(formatter.format(expected)));
    }

    test('should build a simple parameter inside a method context', () {
      final paramSpec = SyntaxBuilder.parameter(name: 'id', type: cb.refer('int'));
      // Test the parameter by putting it inside a method.
      final methodSpec = SyntaxBuilder.method(name: 'm', requiredParameters: [paramSpec]);
      expectSpec(methodSpec, 'void m(int id) {}');
    });

    test('should build a constructor with a `toThis` parameter', () {
      final spec = SyntaxBuilder.constructor(
        constant: true,
        requiredParameters: [SyntaxBuilder.parameter(name: '_repo', toThis: true)],
      );
      final classSpec = cb.Class((b) => b..name = 'MyClass'..constructors.add(spec));
      expectSpec(classSpec, 'class MyClass { const MyClass(this._repo); }');
    });

    test('should build a final field', () {
      final spec = SyntaxBuilder.field(
        name: '_repository',
        modifier: cb.FieldModifier.final$,
        type: cb.refer('AuthRepository'),
      );
      expectSpec(spec, 'final AuthRepository _repository;');
    });

    test('should build a lambda method with a valid expression body', () {
      final spec = SyntaxBuilder.method(
        name: 'call',
        returns: cb.refer('void'),
        isLambda: true,
        annotations: [cb.refer('override')],
        // A lambda body must be a single expression that can be returned.
        // A print statement is not an expression, but a function call is.
        // We'll test with a simple literal value.
        body: cb.literal(true).statement,
      );
      // The output will be a valid statement that can be parsed.
      expectSpec(spec, '@override void call() => true;');
    });

    test('should build a record type definition', () {
      final spec = SyntaxBuilder.typeDef(
        name: '_MyParams',
        definition: SyntaxBuilder.recordType(namedFields: {
          'id': cb.refer('int'),
          'name': cb.refer('String'),
        }),
      );
      expectSpec(spec, 'typedef _MyParams = ({int id, String name});');
    });

    group('useCase builder', () {
      test('should build a complete NullaryUseCase class', () {
        final spec = SyntaxBuilder.useCase(
          useCaseName: 'GetCurrentUser',
          repoClassName: 'AuthRepository',
          methodName: 'getCurrentUser',
          returnType: cb.refer('FutureEither<User?>'),
          baseClassName: cb.refer('NullaryUsecase'),
          genericTypes: [cb.refer('User?')],
          callParams: [],
          repoCallPositionalArgs: [],
          repoCallNamedArgs: {},
          // Use the canonical way to build an annotation expression.
          annotations: [cb.refer('Injectable').call([])],
        ).first;

        const expected = '''
          @Injectable()
          final class GetCurrentUser implements NullaryUsecase<User?> {
            const GetCurrentUser(this._repository);

            final AuthRepository _repository;

            @override
            FutureEither<User?> call() => _repository.getCurrentUser();
          }
        ''';
        expectSpec(spec, expected);
      });

      test('should build a complete UnaryUseCase class with a record parameter', () {
        final spec = SyntaxBuilder.useCase(
          useCaseName: 'SaveUser',
          repoClassName: 'AuthRepository',
          methodName: 'saveUser',
          returnType: cb.refer('FutureEither<void>'),
          baseClassName: cb.refer('UnaryUsecase'),
          genericTypes: [cb.refer('void'), cb.refer('_SaveUserParams')],
          callParams: [SyntaxBuilder.parameter(name: 'params', type: cb.refer('_SaveUserParams'))],
          repoCallPositionalArgs: [],
          repoCallNamedArgs: {
            'name': cb.refer('params').property('name'),
            'email': cb.refer('params').property('email'),
          },
          annotations: [],
        ).first;

        const expected = '''
          final class SaveUser implements UnaryUsecase<void, _SaveUserParams> {
            const SaveUser(this._repository);

            final AuthRepository _repository;

            @override
            FutureEither<void> call(_SaveUserParams params) =>
                _repository.saveUser(name: params.name, email: params.email);
          }
        ''';
        expectSpec(spec, expected);
      });
    });
  });
}
