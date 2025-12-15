import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:test/test.dart';

class TestNamingLogic with NamingLogic {}

void main() {
  final logic = TestNamingLogic();

  group('NamingLogic', () {
    group('validateName', () {
      test('should match simple {name} suffix pattern', () {
        const pattern = r'${name}UseCase';

        expect(logic.validateName('LoginUseCase', pattern), isTrue);
        expect(logic.validateName('GetUsersUseCase', pattern), isTrue);

        // Mismatches
        expect(logic.validateName('LoginRepository', pattern), isFalse);
        expect(
          logic.validateName('UseCase', pattern),
          isFalse,
          reason: r'${name} requires at least one PascalCase character',
        );
      });

      test('should enforce strict PascalCase for {name}', () {
        const pattern = r'${name}';

        expect(logic.validateName('User', pattern), isTrue);
        expect(logic.validateName('NetworkManager', pattern), isTrue);

        // Failures
        expect(logic.validateName('user', pattern), isFalse); // lowercase start
        expect(logic.validateName('validUser', pattern), isFalse); // camelCase
        expect(logic.validateName('_User', pattern), isFalse); // underscore
        expect(logic.validateName('User_Name', pattern), isFalse); // snake_case inside
      });

      test('should match prefix patterns', () {
        const pattern = r'I${name}'; // e.g. Interface naming

        expect(logic.validateName('IUser', pattern), isTrue);
        expect(logic.validateName('User', pattern), isFalse);
      });

      test('should match {affix} wildcard correctly', () {
        const pattern = r'${affix}Repository';

        // Affix can be anything (or empty)
        expect(logic.validateName('AuthRepository', pattern), isTrue);
        expect(logic.validateName('MockAuthRepository', pattern), isTrue);
        expect(logic.validateName('Repository', pattern), isTrue); // affix matches empty

        expect(logic.validateName('AuthService', pattern), isFalse);
      });

      test('should support standard Regex syntax (OR groups)', () {
        // Commonly used for "Bloc OR Cubit"
        const pattern = r'${name}(Bloc|Cubit)';

        expect(logic.validateName('AuthBloc', pattern), isTrue);
        expect(logic.validateName('AuthCubit', pattern), isTrue);

        expect(logic.validateName('AuthController', pattern), isFalse);
      });

      test('should handle Antipattern regexes', () {
        // e.g. forbid 'Impl' at the end
        const pattern = r'${name}Impl';

        expect(logic.validateName('UserImpl', pattern), isTrue);
        expect(logic.validateName('User', pattern), isFalse);
      });

      test('should match exact literals', () {
        const pattern = 'BaseEntity';
        expect(logic.validateName('BaseEntity', pattern), isTrue);
        expect(logic.validateName('OtherEntity', pattern), isFalse);
      });
    });

    group('generateExample', () {
      test('should replace {name} with "Login"', () {
        expect(logic.generateExample(r'${name}UseCase'), 'LoginUseCase');
      });

      test('should replace {affix} with "My"', () {
        expect(logic.generateExample(r'${affix}Repository'), 'MyRepository');
      });

      test('should clean up regex characters for display', () {
        // Logic removes ( ) | \ to make the example look like a class name
        // Pattern: {name}(Bloc|Cubit) -> LoginBlocCubit
        expect(logic.generateExample(r'${name}(Bloc|Cubit)'), 'LoginBlocCubit');
      });
    });
  });
}
