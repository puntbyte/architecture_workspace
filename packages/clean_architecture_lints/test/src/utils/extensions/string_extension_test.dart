// test/src/utils/extensions/string_extension_test.dart

import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:test/test.dart';

void main() {
  group('StringExtension', () {
    group('toPascalCase', () {
      test('should convert a camelCase string to PascalCase', () {
        expect('getUserProfile'.toPascalCase(), 'GetUserProfile');
      });

      test('should convert a snake_case string to PascalCase', () {
        expect('get_user_profile'.toPascalCase(), 'GetUserProfile');
      });

      test('should convert a kebab-case string to PascalCase', () {
        expect('get-user-profile'.toPascalCase(), 'GetUserProfile');
      });

      test('should capitalize a single lowercase word', () {
        expect('user'.toPascalCase(), 'User');
      });

      test('should leave a PascalCase string unchanged', () {
        expect('UserProfile'.toPascalCase(), 'UserProfile');
      });

      test('should correctly handle acronyms in the middle', () {
        // This is a crucial test that the original implementation fails.
        expect('fetchApiData'.toPascalCase(), 'FetchAPIData');
      });

      test('should correctly handle acronyms at the end', () {
        expect('getUserDTO'.toPascalCase(), 'GetUserDTO');
      });

      test('should correctly handle single-letter words and acronyms like Id', () {
        expect('userId'.toPascalCase(), 'UserID');
      });

      test('should return an empty string when input is empty', () {
        expect(''.toPascalCase(), '');
      });
    });

    group('toSnakeCase', () {
      test('should convert a PascalCase string to snake_case', () {
        expect('GetUserProfile'.toSnakeCase(), 'get_user_profile');
      });

      test('should convert a camelCase string to snake_case', () {
        expect('getUserProfile'.toSnakeCase(), 'get_user_profile');
      });

      test('should leave a snake_case string unchanged', () {
        expect('get_user_profile'.toSnakeCase(), 'get_user_profile');
      });

      test('should handle a single PascalCase word', () {
        expect('User'.toSnakeCase(), 'user');
      });

      test('should correctly handle acronyms at the end of a string', () {
        expect('UserDTO'.toSnakeCase(), 'user_dto');
      });

      test('should correctly handle acronyms in the middle of a string', () {
        expect('getAPIData'.toSnakeCase(), 'get_api_data');
      });

      test('should correctly handle numbers', () {
        expect('getUserV2'.toSnakeCase(), 'get_user_v2');
      });

      test('should return an empty string when input is empty', () {
        expect(''.toSnakeCase(), '');
      });
    });

    // --- NEW: Dedicated Group for splitPascalCase ---
    group('splitPascalCase', () {
      test('should split a simple two-word name', () {
        expect('GetUser'.splitPascalCase(), ['Get', 'User']);
      });

      test('should split a multi-word name', () {
        expect('SendPasswordResetEmail'.splitPascalCase(), ['Send', 'Password', 'Reset', 'Email']);
      });

      test('should handle a single-word name', () {
        expect('User'.splitPascalCase(), ['User']);
      });

      test('should correctly handle an acronym at the end', () {
        expect('HandleDTO'.splitPascalCase(), ['Handle', 'DTO']);
      });

      test('should correctly handle an acronym in the middle', () {
        expect('GetAPIData'.splitPascalCase(), ['Get', 'API', 'Data']);
      });

      test('should correctly handle a single-letter word', () {
        expect('AThing'.splitPascalCase(), ['A', 'Thing']);
      });

      test('should return an empty list when the input is empty', () {
        expect(''.splitPascalCase(), isEmpty);
      });
    });
  });
}
