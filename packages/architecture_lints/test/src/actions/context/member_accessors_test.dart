import 'package:architecture_lints/src/actions/context/architectural_member_accessors.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:expressions/expressions.dart';
import 'package:test/test.dart';

void main() {
  group('MemberAccessors', () {
    late ExpressionEvaluator evaluator;

    setUp(() {
      evaluator = ExpressionEvaluator(memberAccessors: ArchitectureMemberAccessors.getAll());
    });

    // Helper to eval specific object properties
    dynamic eval(dynamic object, String property) {
      // We simulate "obj.prop" expression
      return evaluator.eval(
        Expression.parse('obj.$property'),
        {'obj': object},
      );
    }

    group('StringWrapper Accessors', () {
      test('should resolve casing properties', () {
        const str = StringWrapper('user_profile');

        // Note: The accessors return StringWrapper, we unwrap to String for assertions
        expect(eval(str, 'pascalCase').toString(), 'UserProfile');
        expect(eval(str, 'camelCase').toString(), 'userProfile');
        expect(eval(str, 'snakeCase').toString(), 'user_profile');
        expect(eval(str, 'constantCase').toString(), 'USER_PROFILE');
        expect(eval(str, 'dotCase').toString(), 'user.profile');
        expect(eval(str, 'pathCase').toString(), 'user/profile');
        expect(eval(str, 'paramCase').toString(), 'user-profile');
        expect(eval(str, 'headerCase').toString(), 'User-Profile');
        expect(eval(str, 'titleCase').toString(), 'User Profile');
        expect(eval(str, 'sentenceCase').toString(), 'User profile');
      });

      test('should resolve standard properties', () {
        const str = StringWrapper('abc');
        expect(eval(str, 'length'), 3);
        expect(eval(str, 'isEmpty'), false);
        expect(eval(str, 'isNotEmpty'), true);
        expect(eval(str, 'value'), 'abc');
      });

      test('should throw on unknown property', () {
        const str = StringWrapper('abc');
        expect(() => eval(str, 'unknownProp'), throwsA(isA<ArgumentError>()));
      });
    });

    group('ListWrapper Accessors', () {
      test('should resolve helper booleans', () {
        final empty = ListWrapper([]);
        expect(eval(empty, 'isEmpty'), true);
        expect(eval(empty, 'hasMany'), false);

        final single = ListWrapper(['a']);
        expect(eval(single, 'isSingle'), true);
        expect(eval(single, 'hasMany'), false);

        final many = ListWrapper(['a', 'b']);
        expect(eval(many, 'isSingle'), false);
        expect(eval(many, 'hasMany'), true);
        expect(eval(many, 'length'), 2);
      });

      test('should resolve first/last', () {
        final list = ListWrapper(['first', 'last']);
        expect(eval(list, 'first'), 'first');
        expect(eval(list, 'last'), 'last');
      });
    });

    group('Definition Accessors', () {
      test('should resolve properties', () {
        const def = Definition(
          types: ['MyClass'],
          imports: ['pkg/file.dart'],
        );

        expect(eval(def, 'type'), 'MyClass');
        expect(eval(def, 'import'), 'pkg/file.dart');
      });
    });

    // Note: NodeWrapper, MethodWrapper, TypeWrapper accessors rely on complex AST objects.
    // They are implicitly covered by `VariableResolver` integration tests
    // or the `wrappers_test.dart` we wrote earlier.
    // Testing them here would require mocking internal AST getters which is verbose.
  });
}