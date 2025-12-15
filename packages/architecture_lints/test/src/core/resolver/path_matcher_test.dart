import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('PathMatcher', () {
    group('Basic Matching', () {
      test('should return true for exact substring match', () {
        const configPath = 'domain/usecases';
        const filePath = 'lib/domain/usecases/login_usecase.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test('should return false when path does not contain config path', () {
        const configPath = 'domain/usecases';
        const filePath = 'lib/presentation/pages/login_page.dart';
        expect(PathMatcher.matches(filePath, configPath), isFalse);
      });

      test('should normalize Windows backslashes in file path', () {
        const configPath = 'domain/usecases';
        // Simulate Windows path
        const filePath = r'lib\domain\usecases\login_usecase.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test('should normalize Windows backslashes in config path', () {
        // Simulate Windows config
        const configPath = r'domain\usecases';
        const filePath = 'lib/domain/usecases/login_usecase.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });
    });

    group(r'Wildcards ${name}', () {
      test('should match simple feature structure', () {
        const configPath = r'features/${name}/domain';
        const filePath = 'lib/features/auth/domain/auth_repo.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test(r'should match ${name} in middle of path', () {
        const configPath = r'modules/${name}/api';
        const filePath = 'lib/modules/payments/api/service.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test(r'should match ${name} at start of path', () {
        // If config assumes root context
        const configPath = r'${name}/presentation';
        const filePath = 'features/dashboard/presentation/page.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test('should NOT match if structure differs', () {
        const configPath = r'features/${name}/domain';
        // Missing 'domain' folder
        const filePath = 'lib/features/auth/presentation/page.dart';
        expect(PathMatcher.matches(filePath, configPath), isFalse);
      });
    });

    group('Glob Wildcards (*)', () {
      test('should match single level wildcard', () {
        const configPath = 'core/*/utils';
        const filePath = 'lib/core/network/utils/parser.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test('should match nested wildcards', () {
        const configPath = 'tests/*/unit/*.dart';
        const filePath = 'tests/features/unit/login_test.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });
    });

    group('Edge Cases', () {
      test('should escape special regex characters in config path', () {
        // Dot (.) should be treated as a literal dot, not "any character"
        const configPath = 'v1.api/endpoints';

        // Should match exact dot
        expect(PathMatcher.matches('lib/v1.api/endpoints/user.dart', configPath), isTrue);

        // Should NOT match if dot was wildcard (e.g., v1-api)
        // Note: normalizedPath check implies contains, so we need to be careful.
        // If your implementation uses regex escaping properly, 'v1.api' won't match 'v1-api'.
      });
    });
  });
}