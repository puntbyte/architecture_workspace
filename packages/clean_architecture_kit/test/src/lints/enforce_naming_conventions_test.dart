// test/src/lints/enforce_naming_conventions_test.dart

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_kit/src/lints/structure/enforce_naming_conventions.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

/// A test helper that runs the EnforceNamingConventions lint and captures diagnostic reports.
Future<List<Map<String, dynamic>>> runNamingLint(
    String source,
    String path, {
      required CleanArchitectureConfig config,
    }) async {
  final reporter = MockDiagnosticReporter();
  final lint = EnforceNamingConventions(config: config, layerResolver: LayerResolver(config));
  final resolver = MockCustomLintResolver();
  final context = MockCustomLintContext();
  final registry = MockLintRuleNodeRegistry();

  when(() => resolver.source).thenReturn(FakeSource(fullName: path));
  when(() => context.registry).thenReturn(registry);

  void Function(ClassDeclaration)? capturedCallback;
  when(() => registry.addClassDeclaration(any())).thenAnswer((invocation) {
    capturedCallback = invocation.positionalArguments.first as void Function(ClassDeclaration);
  });

  final captured = <Map<String, dynamic>>[];
  when(() => reporter.atToken(any(), any())).thenAnswer((invocation) {
    final code = invocation.positionalArguments[1] as LintCode;
    captured.add({'message': code.problemMessage});
  });

  lint.run(resolver, reporter, context);
  expect(capturedCallback, isNotNull, reason: 'addClassDeclaration was not called');

  final parsed = parseString(content: source, throwIfDiagnostics: false);
  final classNode = parsed.unit.declarations.whereType<ClassDeclaration>().first;
  capturedCallback!(classNode);

  return captured;
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeToken());
    registerFallbackValue(FakeLintCode());
  });

  group('EnforceNamingConventions Lint', () {
    test('should not report a violation when a class has the correct name for its location', () async {
      final config = makeConfig(entityNaming: '{{name}}');
      const source = 'class User {}';
      // Path correctly identifies this as an 'entity' file.
      final path = '/project/lib/features/auth/domain/entities/user.dart';

      final captured = await runNamingLint(source, path, config: config);

      expect(captured, isEmpty);
    });

    test('should report a "pattern mismatch" violation for an incorrect name', () async {
      final config = makeConfig(modelNaming: '{{name}}Model');
      const source = 'class UserDTO {}';
      // Path correctly identifies this as a 'model' file.
      final path = '/project/lib/features/auth/data/models/user_dto.dart';

      final captured = await runNamingLint(source, path, config: config);

      expect(captured, hasLength(1));
      expect(captured.first['message'], contains('does not match the required `{{name}}Model` convention'));
    });

    test('should report a "forbidden pattern" violation for an anti-pattern match', () async {
      final config = makeConfig(
        entityNaming: {
          'pattern': '{{name}}',
          'anti_pattern': ['{{name}}Entity'], // Explicitly forbid '...Entity' suffix
        },
      );
      const source = 'class UserEntity {}';
      // Path correctly identifies this as an 'entity' file.
      final path = '/project/lib/features/auth/domain/entities/user_entity.dart';

      final captured = await runNamingLint(source, path, config: config);

      expect(captured, hasLength(1));
      expect(captured.first['message'], contains('uses a forbidden pattern'));
    });

    test('should stay silent when a class name suggests it is in the wrong location', () async {
      // This is the crucial test for the lint's cooperative behavior.
      final config = makeConfig(
        // The lint knows a class in an 'entities' folder should be named like '{{name}}'.
        entityNaming: '{{name}}',
        // And it knows a class named like '{{name}}Model' belongs in a 'models' folder.
        modelNaming: '{{name}}Model',
      );

      // A class named like a Model, but located in an `entities` directory.
      const source = 'class SomeDataModel {}';
      final path = '/project/lib/features/auth/domain/entities/some_data_model.dart';

      final captured = await runNamingLint(source, path, config: config);

      // This lint should NOT fire. It correctly identifies this as a location
      // problem and stays silent, allowing `enforce_file_and_folder_location` to report it.
      expect(captured, isEmpty, reason: 'This is a location violation, not a naming violation.');
    });
  });
}