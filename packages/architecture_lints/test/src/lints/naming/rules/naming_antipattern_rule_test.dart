import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/lints/naming/rules/naming_antipattern_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class TestNamingAntipatternRule extends NamingAntipatternRule {
  final ArchitectureConfig mockConfig;

  const TestNamingAntipatternRule(this.mockConfig);

  @override
  Future<void> startUp(
      CustomLintResolver resolver,
      CustomLintContext context,
      ) async {
    context.sharedState[ArchitectureConfig] = mockConfig;
    context.sharedState[FileResolver] = FileResolver(mockConfig);
    await super.startUp(resolver, context);
  }
}

void main() {
  group('NamingAntipatternRule', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('naming_anti_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<List<Diagnostic>> runLint({
      required String relativePath,
      required String content,
      required ArchitectureConfig config,
    }) async {
      final pathParts = relativePath.split('/');
      final fullPath = p.joinAll([tempDir.path, ...pathParts]);

      final file = File(fullPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(content);

      final normalizedPath = p.normalize(file.absolute.path);
      final result = await resolveFile(path: normalizedPath);

      if (result is! ResolvedUnitResult) {
        throw StateError('Failed to resolve file: $normalizedPath');
      }

      final rule = TestNamingAntipatternRule(config);
      return rule.testRun(result);
    }

    test('should report warning when class name matches antipattern', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentDefinition(
            id: 'entity',
            paths: ['domain/entities'],
            antipatterns: ['{{name}}Entity'],
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/entities/user_entity.dart',
        content: 'class UserEntity {}',
      );

      expect(errors, hasLength(1));
      expect(errors.first.severity, Severity.warning);
      expect(errors.first.message, contains('UserEntity'));
    });

    test('should pass if class name matches NO antipattern', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentDefinition(
            id: 'entity',
            paths: ['domain/entities'],
            antipatterns: ['{{name}}Entity'],
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/entities/user.dart',
        content: 'class User {}',
      );

      expect(errors, isEmpty);
    });

    test('should support multiple antipatterns', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentDefinition(
            id: 'port',
            paths: ['domain/ports'],
            antipatterns: ['{{name}}Interface', 'Abstract{{name}}'],
          ),
        ],
      );

      // Check first pattern
      final errors1 = await runLint(
        config: config,
        relativePath: 'lib/domain/ports/auth_interface.dart',
        content: 'class AuthInterface {}',
      );
      expect(errors1, hasLength(1));
      expect(errors1.first.message, contains('AuthInterface'));

      // Check second pattern
      final errors2 = await runLint(
        config: config,
        relativePath: 'lib/domain/ports/abstract_auth.dart',
        content: 'class AbstractAuth {}',
      );
      expect(errors2, hasLength(1));
      expect(errors2.first.message, contains('AbstractAuth'));
    });
  });
}