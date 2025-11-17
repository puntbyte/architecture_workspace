// test/src/utils/naming_utils_test.dart

import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('NamingUtils', () {
    group('getExpectedUseCaseClassName', () {
      test('should create correct class name from a simple {{name}} template', () {
        final config = makeConfig(useCaseNaming: '{{name}}');
        final result = NamingUtils.getExpectedUseCaseClassName('getUser', config);
        expect(result, 'GetUser');
      });

      test('should create correct class name from a suffixed template', () {
        final config = makeConfig(useCaseNaming: '{{name}}Action');
        final result = NamingUtils.getExpectedUseCaseClassName('getUser', config);
        expect(result, 'GetUserAction');
      });
    });

    group('validateName', () {
      test('should return true for a correct suffix', () {
        expect(NamingUtils.validateName(name: 'UserModel', template: '{{name}}Model'), isTrue);
      });

      test('should return false for an incorrect suffix', () {
        expect(NamingUtils.validateName(name: 'User', template: '{{name}}Model'), isFalse);
      });

      test('should return true for a simple name with {{name}} template', () {
        expect(NamingUtils.validateName(name: 'User', template: '{{name}}'), isTrue);
      });

      test('should return false for a suffixed name with {{name}} template', () {
        expect(NamingUtils.validateName(name: 'UserEntity', template: '{{name}}'), isFalse);
      });

      test('should return true for a correct {{kind}}{{name}} pattern', () {
        expect(
          NamingUtils.validateName(
            name: 'DefaultAuthRepository',
            template: '{{kind}}{{name}}Repository',
          ),
          isTrue,
        );
      });

      test('should return true for a different kind in {{kind}}{{name}} pattern', () {
        expect(
          NamingUtils.validateName(
            name: 'FirebaseAuthRepository',
            template: '{{kind}}{{name}}Repository',
          ),
          isTrue,
        );
      });

      test('should return false for a missing kind in {{kind}}{{name}} pattern', () {
        expect(
          NamingUtils.validateName(name: 'AuthRepository', template: '{{kind}}{{name}}Repository'),
          isFalse,
        );
      });

      test('should correctly handle templates with special characters', () {
        expect(
          NamingUtils.validateName(name: '_GetUserParams', template: '_{{name}}Params'),
          isTrue,
        );
      });
    });
  });
}
