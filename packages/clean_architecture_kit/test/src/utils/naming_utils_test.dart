// test/src/utils/naming_utils_test.dart

import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:test/test.dart';

// A lightweight helper to create a config with specific naming conventions for testing.
CleanArchitectureConfig makeTestConfig({
  String entity = '{{name}}',
  String model = '{{name}}Model',
  String useCase = '{{name}}',
  String repoInterface = '{{name}}Repository',
  String repoImpl = '{{type}}{{name}}Repository',
}) {
  return CleanArchitectureConfig.fromMap({
    'naming_conventions': {
      'entity': entity,
      'model': model,
      'use_case': useCase,
      'repository_interface': repoInterface,
      'repository_implementation': repoImpl,
    },
    'layer_definitions': {},
    'type_safety': {},
    'inheritance': {},
    'generation_options': {},
    'service_locator': {},
  });
}

void main() {
  group('NamingUtils', () {
    group('getExpectedUseCaseClassName', () {
      test('should create correct class name with a simple {{name}} template', () {
        final config = makeTestConfig();
        final result = NamingUtils.getExpectedUseCaseClassName('getUser', config);
        expect(result, 'GetUser');
      });

      test('should create correct class name with a {{name}}Usecase template', () {
        final config = makeTestConfig(useCase: '{{name}}Usecase');
        final result = NamingUtils.getExpectedUseCaseClassName('getUser', config);
        expect(result, 'GetUserUsecase');
      });

      test('should handle snake_case method names', () {
        final config = makeTestConfig(useCase: '{{name}}UseCase');
        final result = NamingUtils.getExpectedUseCaseClassName('get_all_users', config);
        // Assuming your `toPascalCase` handles this, which it should.
        expect(result, 'GetAllUsersUseCase');
      });
    });

    group('extractName', () {
      test('should extract base name from a simple suffix template', () {
        final result = NamingUtils.extractName(name: 'UserModel', template: '{{name}}Model');
        expect(result, 'User');
      });

      test('should extract base name from a simple prefix template', () {
        final result = NamingUtils.extractName(name: 'DefaultUser', template: 'Default{{name}}');
        expect(result, 'User');
      });

      test('should extract base name from a {{type}}{{name}} template', () {
        final result = NamingUtils.extractName(
          name: 'DefaultAuthRepository',
          template: '{{type}}{{name}}Repository',
        );
        expect(result, 'Auth');
      });

      test('should return null if name does not match template', () {
        final result = NamingUtils.extractName(name: 'UserDTO', template: '{{name}}Model');
        expect(result, isNull);
      });

      test('should return the full name if template is just {{name}}', () {
        final result = NamingUtils.extractName(name: 'User', template: '{{name}}');
        expect(result, 'User');
      });
    });

    group('validateName', () {
      // --- Basic Suffix/Prefix ---
      test('should return true for a correct suffix', () {
        expect(NamingUtils.validateName(name: 'UserModel', template: '{{name}}Model'), isTrue);
      });

      test('should return true for a correct prefix', () {
        expect(NamingUtils.validateName(name: 'DefaultAuth', template: 'Default{{name}}'), isTrue);
      });

      test('should return false for an incorrect suffix', () {
        expect(NamingUtils.validateName(name: 'User', template: '{{name}}Model'), isFalse);
      });

      // --- Simple {{name}} ---
      test('should return true for a simple name with {{name}} template', () {
        expect(NamingUtils.validateName(name: 'User', template: '{{name}}'), isTrue);
      });

      test('should return false for a suffixed name with {{name}} template', () {
        // This is important for the anti-pattern logic.
        expect(NamingUtils.validateName(name: 'UserEntity', template: '{{name}}'), isFalse);
      });

      // --- Complex {{type}}{{name}} ---
      test('should return true for a correct {{type}}{{name}} pattern', () {
        expect(
          NamingUtils.validateName(
            name: 'DefaultAuthRepository',
            template: '{{type}}{{name}}Repository',
          ),
          isTrue,
        );
      });

      test('should return true for a different type in {{type}}{{name}} pattern', () {
        expect(
          NamingUtils.validateName(
            name: 'FirebaseAuthRepository',
            template: '{{type}}{{name}}Repository',
          ),
          isTrue,
        );
      });

      test('should return false for a missing type in {{type}}{{name}} pattern', () {
        expect(
          NamingUtils.validateName(name: 'AuthRepository', template: '{{type}}{{name}}Repository'),
          isFalse,
        );
      });

      // --- Edge Cases with Special Characters ---
      test('should correctly handle templates with underscores', () {
        expect(
          NamingUtils.validateName(name: '_GetUserParams', template: '_{{name}}Params'),
          isTrue,
        );
      });

      test('should return false for an incorrect underscore pattern', () {
        expect(
          NamingUtils.validateName(name: 'GetUserParams', template: '_{{name}}Params'),
          isFalse,
        );
      });

      // Literal-only template
      test('literal-only template should match exactly', () {
        expect(NamingUtils.validateName(name: 'MySpecial', template: 'MySpecial'), isTrue);
        expect(NamingUtils.validateName(name: 'MySpecialX', template: 'MySpecial'), isFalse);
      });

      // {{type}}-only template
      test('{{type}}-only template should require a Pascal token', () {
        expect(NamingUtils.validateName(name: 'Firebase', template: '{{type}}'), isTrue);
        expect(
          NamingUtils.validateName(name: 'firebase', template: '{{type}}'),
          isFalse,
        ); // lowercase start
      });

      // adjacent placeholders: ensure short type and name allowed
      test('adjacent {{type}}{{name}} with 1-char type should pass', () {
        expect(
          NamingUtils.validateName(name: 'FAuthRepository', template: '{{type}}{{name}}Repository'),
          isTrue,
        );
      });

      test('adjacent {{type}}{{name}} with 1-char name should pass', () {
        expect(
          NamingUtils.validateName(
            name: 'DefaultARepository',
            template: '{{type}}{{name}}Repository',
          ),
          isTrue,
        );
      });

      // empty name should be rejected
      test('empty name should be rejected', () {
        expect(NamingUtils.validateName(name: '', template: '{{name}}'), isFalse);
        expect(NamingUtils.validateName(name: '', template: 'Prefix{{name}}Suffix'), isFalse);
      });

      // lowercase start should be rejected for Pascal tokens
      test('lowercase start is rejected for Pascal tokens', () {
        expect(NamingUtils.validateName(name: 'userModel', template: '{{name}}Model'), isFalse);
      });

      // spaces or invalid characters are rejected
      test('names with spaces are rejected', () {
        expect(
          NamingUtils.validateName(name: 'Auth Repo', template: '{{type}}{{name}}Repository'),
          isFalse,
        );
      });

      // digits inside tokens (allowed by current regex) - assert expected behavior
      test('digits inside Pascal token are allowed', () {
        expect(
          NamingUtils.validateName(
            name: 'V1AuthRepository',
            template: '{{type}}{{name}}Repository',
          ),
          isTrue,
        );
        expect(NamingUtils.validateName(name: 'Auth1Model', template: '{{name}}Model'), isTrue);
      });

      // template with regex special characters are escaped
      test('template with dot should match literal dot', () {
        expect(NamingUtils.validateName(name: 'User.impl', template: '{{name}}.impl'), isTrue);
        expect(NamingUtils.validateName(name: 'Userximpl', template: '{{name}}.impl'), isFalse);
      });

      // repeated placeholders (weird templates) – assert behavior
      test('repeated placeholders template should match two tokens', () {
        // Template: '{{name}}{{name}}DTO' => expects two Pascal tokens concatenated, e.g. 'UserUserDTO'
        expect(
          NamingUtils.validateName(name: 'UserUserDTO', template: '{{name}}{{name}}DTO'),
          isTrue,
        );
        expect(NamingUtils.validateName(name: 'UserDTO', template: '{{name}}{{name}}DTO'), isFalse);
      });

      // prefixes or suffixes that are substrings of tokens (partitioning check)
      test('partitioning should not mis-assign suffix as part of name', () {
        // The suffix "Repository" is literal; ensure partitioning works
        expect(
          NamingUtils.validateName(
            name: 'DefaultAuthRepository',
            template: '{{type}}{{name}}Repository',
          ),
          isTrue,
        );
        expect(
          NamingUtils.validateName(
            name: 'DefaultRepository',
            template: '{{type}}{{name}}Repository',
          ),
          isFalse,
        ); // missing name
      });
    });
  });
}
