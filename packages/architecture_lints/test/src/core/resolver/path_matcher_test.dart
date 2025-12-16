import 'package:architecture_lints/src/engines/file/path_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('PathMatcher', () {

    group('Basic Matching', () {
      test('should return true for exact substring match inside path', () {
        const configPath = 'domain/usecases';
        const filePath = 'lib/domain/usecases/login_usecase.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test('should return true when config matches the end of the directory structure', () {
        const configPath = 'data/repositories';
        // Matches .../data/repositories/file.dart
        const filePath = 'lib/features/auth/data/repositories/auth_repo.dart';
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

    group('Boundary Checks (Partial Matching)', () {
      test('should NOT match partial folder names (middle)', () {
        const configPath = 'port';
        // "support" contains "port", but it is not a folder boundary
        const filePath = 'lib/support/utils.dart';
        expect(PathMatcher.matches(filePath, configPath), isFalse);
      });

      test('should NOT match partial folder names (end)', () {
        const configPath = 'auth';
        // "author" ends with "auth" prefix, but is different folder
        const filePath = 'lib/features/author/file.dart';
        expect(PathMatcher.matches(filePath, configPath), isFalse);
      });

      test('should match exact folder name', () {
        const configPath = 'port';
        const filePath = 'lib/domain/port/auth_port.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });
    });

    group('Wildcards {{name}}', () {
      test('should match simple feature structure', () {
        const configPath = 'features/{{name}}/domain';
        const filePath = 'lib/features/auth/domain/auth_repo.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test('should match {{name}} in middle of path', () {
        const configPath = 'modules/{{name}}/api';
        const filePath = 'lib/modules/payments/api/service.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test('should match {{name}} at start of path', () {
        // If config assumes root context like '{{name}}/presentation'
        // And file is 'lib/dashboard/presentation/page.dart'
        const configPath = '{{name}}/presentation';
        const filePath = 'lib/dashboard/presentation/page.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test('should match when {{name}} is the only variable', () {
        const configPath = 'features/{{name}}';
        const filePath = 'lib/features/login/data/repo.dart';
        expect(PathMatcher.matches(filePath, configPath), isTrue);
      });

      test('should NOT match if structure differs', () {
        const configPath = 'features/{{name}}/domain';
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

    group('File Extensions (Excludes)', () {
      test('should match strict extension wildcards', () {
        // This is the logic: if (configPath.startsWith('*') && !configPath.contains('/'))
        const configPath = '*.g.dart';

        expect(PathMatcher.matches('lib/user.g.dart', configPath), isTrue);
        expect(PathMatcher.matches('lib/feature/user.g.dart', configPath), isTrue);
        expect(PathMatcher.matches('lib/user.dart', configPath), isFalse);
      });

      test('should match standard glob extension logic', () {
        // If the config is '**/*.freezed.dart' (standard glob syntax),
        // it falls through to the regex match which handles '*' as '.*'
        const configPath = '**/*.freezed.dart';
        const filePath = 'lib/models/user.freezed.dart';

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
        // With correct escaping, this returns False.
        expect(PathMatcher.matches('lib/v1-api/endpoints/user.dart', configPath), isFalse);
      });
    });
  });
}