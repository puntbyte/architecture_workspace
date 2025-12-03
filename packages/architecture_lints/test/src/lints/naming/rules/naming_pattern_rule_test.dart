import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/naming/rules/naming_pattern_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class TestNamingPatternRule extends NamingPatternRule {
  final ArchitectureConfig mockConfig;

  const TestNamingPatternRule(this.mockConfig);

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
  group('NamingPatternRule', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('naming_rule_test_');
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

      final rule = TestNamingPatternRule(config);
      return rule.testRun(result);
    }

    test('should report no error when class name matches single pattern', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentConfig(
            id: 'usecase',
            paths: ['domain/usecases'],
            patterns: ['{{name}}UseCase'],
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/usecases/login_usecase.dart',
        content: 'class LoginUseCase {}',
      );

      expect(errors, isEmpty);
    });

    test('should report no error when class name matches ANY of multiple patterns', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentConfig(
            id: 'manager',
            paths: ['presentation/managers'],
            // Allow both Cubit AND Bloc suffixes
            patterns: ['{{name}}Cubit', '{{name}}Bloc'],
          ),
        ],
      );

      // Check Cubit
      final errorsCubit = await runLint(
        config: config,
        relativePath: 'lib/presentation/managers/auth_cubit.dart',
        content: 'class AuthCubit {}',
      );
      expect(errorsCubit, isEmpty);

      // Check Bloc
      final errorsBloc = await runLint(
        config: config,
        relativePath: 'lib/presentation/managers/auth_bloc.dart',
        content: 'class AuthBloc {}',
      );
      expect(errorsBloc, isEmpty);
    });

    test('should report error when class name matches NONE of multiple patterns', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentConfig(
            id: 'manager',
            paths: ['presentation/managers'],
            patterns: ['{{name}}Cubit', '{{name}}Bloc'],
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/presentation/managers/auth_controller.dart',
        content: 'class AuthController {}', // Matches neither
      );

      expect(errors, hasLength(1));
      // Message should mention BOTH options
      expect(errors.first.message, contains('{{name}}Cubit OR {{name}}Bloc'));
    });

    test('should ignore files that do not match any component path', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentConfig(
              id: 'usecase', paths: ['domain/usecases'], patterns: ['{{name}}']),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/other/file.dart',
        content: 'class AnyName {}',
      );

      expect(errors, isEmpty);
    });
  });
}