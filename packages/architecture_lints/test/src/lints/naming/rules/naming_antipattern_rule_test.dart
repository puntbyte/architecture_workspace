import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
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

    test('should report WARNING when class name matches antipattern', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentConfig(
            id: 'entity',
            paths: ['domain/entities'],
            // Allowed: {{name}}
            // Forbidden: {{name}}Entity
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
      expect(errors.first.severity, Severity.warning); // Check severity
      expect(errors.first.message, contains('UserEntity'));
      expect(errors.first.correctionMessage, contains('{{name}}Entity'));
    });

    test('should report WARNING when class matches ANY of multiple antipatterns', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentConfig(
            id: 'port',
            paths: ['domain/ports'],
            // Forbidden: Interface suffix OR Abstract prefix
            antipatterns: ['{{name}}Interface', 'Abstract{{name}}'],
          ),
        ],
      );

      // Check First Antipattern
      final errors1 = await runLint(
        config: config,
        relativePath: 'lib/domain/ports/auth_interface.dart',
        content: 'class AuthInterface {}',
      );
      expect(errors1, hasLength(1));

      // Check Second Antipattern
      final errors2 = await runLint(
        config: config,
        relativePath: 'lib/domain/ports/abstract_auth.dart',
        content: 'class AbstractAuth {}',
      );
      expect(errors2, hasLength(1));
    });

    test('should pass if class name matches NO antipattern', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentConfig(
            id: 'entity',
            paths: ['domain/entities'],
            antipatterns: ['{{name}}Entity'],
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/entities/user.dart',
        content: 'class User {}', // Correct name
      );

      expect(errors, isEmpty);
    });

    test('should ignore files if no antipatterns are defined', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentConfig(
            id: 'entity',
            paths: ['domain/entities'],
            antipatterns: [], // Empty list
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/entities/user_entity.dart',
        content: 'class UserEntity {}', // Matches what would usually be bad
      );

      expect(errors, isEmpty);
    });
  });
}