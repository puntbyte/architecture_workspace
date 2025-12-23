import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/lints/naming/rules/naming_antipattern_rule.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

/// Wrapper to inject configuration
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
      tempDir = Directory.systemTemp.createTempSync('antipattern_test_');
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

      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);

      final normalizedPath = p.normalize(file.absolute.path);

      // Use helper to resolve the file context
      // Note: We use the content directly, assuming resolveFile handles the path we just wrote
      final result = await resolveFile(path: normalizedPath);

      if (result is! ResolvedUnitResult) {
        throw StateError('Failed to resolve file: $normalizedPath');
      }

      final rule = TestNamingAntipatternRule(config);
      return rule.testRun(result);
    }

    test('should report error when class name matches antipattern', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentDefinition(
            id: 'entity',
            paths: ['domain/entities'],
            // Rule: Entities cannot end in "Impl"
            antipatterns: ['{{name}}Impl'],
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/entities/user_impl.dart',
        content: 'class UserImpl {}',
      );

      expect(errors, hasLength(1));
      expect(errors.first.diagnosticCode.name, 'arch_naming_antipattern');
      expect(errors.first.message, contains('UserImpl'));
      expect(errors.first.correctionMessage, contains('{{name}}Impl'));
    });

    test('should report error when class name matches ANY of multiple antipatterns', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentDefinition(
            id: 'page',
            paths: ['presentation/pages'],
            // Rule: No "Screen" suffix, No "View" suffix
            antipatterns: ['{{name}}Screen', '{{name}}View'],
          ),
        ],
      );

      // 1. Check Screen
      final errors1 = await runLint(
        config: config,
        relativePath: 'lib/presentation/pages/home_screen.dart',
        content: 'class HomeScreen {}',
      );
      expect(errors1, hasLength(1));
      expect(errors1.first.correctionMessage, contains('{{name}}Screen'));

      // 2. Check View
      final errors2 = await runLint(
        config: config,
        relativePath: 'lib/presentation/pages/login_view.dart',
        content: 'class LoginView {}',
      );
      expect(errors2, hasLength(1));
      expect(errors2.first.correctionMessage, contains('{{name}}View'));
    });

    test('should pass if class name does NOT match antipattern', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentDefinition(
            id: 'entity',
            paths: ['domain/entities'],
            antipatterns: ['{{name}}Impl'],
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/entities/user.dart',
        content: 'class User {}', // "User" does not end in "Impl"
      );

      expect(errors, isEmpty);
    });

    test('should support affix wildcard {{affix}}', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentDefinition(
            id: 'domain_pure',
            paths: ['domain'],
            // Ban anything containing "Widget" anywhere
            antipatterns: ['{{affix}}Widget{{affix}}'],
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/my_widget_helper.dart',
        content: 'class MyWidgetHelper {}',
      );

      expect(errors, hasLength(1));
      expect(errors.first.message, contains('MyWidgetHelper'));
    });

    test('should ignore files that do not match any component path', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentDefinition(
              id: 'entity',
              paths: ['domain/entities'],
              antipatterns: ['{{name}}Impl']
          ),
        ],
      );

      // File in 'data', not 'domain/entities'
      final errors = await runLint(
        config: config,
        relativePath: 'lib/data/user_impl.dart',
        content: 'class UserImpl {}',
      );

      expect(errors, isEmpty);
    });
  });
}