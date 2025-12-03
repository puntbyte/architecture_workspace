import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart'; // 1. Import mocktail
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// 2. Define Mocks
class MockFileResolver extends Mock implements FileResolver {}
class MockArchitectureConfig extends Mock implements ArchitectureConfig {}

// 3. Update the Stub Rule to accept generic Mocks
class MockArchitectureRule extends ArchitectureLintRule {
  final ArchitectureConfig? mockConfig;
  final FileResolver? mockResolver; // We can now inject a mock resolver

  // Spies to verify execution
  bool wasRunWithConfigCalled = false;
  ComponentConfig? capturedComponent;

  MockArchitectureRule({
    this.mockConfig,
    this.mockResolver,
  }) : super(code: _code);

  static const _code = LintCode(
    name: 'mock_arch_rule',
    problemMessage: 'Mock error',
  );

  @override
  Future<void> startUp(
      CustomLintResolver resolver,
      CustomLintContext context,
      ) async {
    // Logic: If we provide mocks in constructor, inject them into SharedState
    // This overrides the default behavior of loading from disk.
    if (mockConfig != null) {
      context.sharedState[ArchitectureConfig] = mockConfig;

      // Inject the Mock Resolver if provided, otherwise create real one
      context.sharedState[FileResolver] = mockResolver ?? FileResolver(mockConfig!);
    } else {
      // If no mock config, let the base class try to load from disk (and fail)
      await super.startUp(resolver, context);
    }
  }

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    ComponentConfig? component,
  }) {
    wasRunWithConfigCalled = true;
    capturedComponent = component;
  }
}

void main() {
  group('ArchitectureLintRule', () {
    late Directory tempDir;
    late MockFileResolver mockResolver;
    late MockArchitectureConfig mockConfig;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('arch_rule_test_');
      mockResolver = MockFileResolver();
      mockConfig = MockArchitectureConfig();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<MockArchitectureRule> runRule({
      required String relativePath,
    }) async {
      // 1. Create dummy file (required for Analyzer to run)
      final pathParts = relativePath.split('/');
      final fullPath = p.joinAll([tempDir.path, ...pathParts]);
      final file = File(fullPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('class TestClass {}');

      // 2. Resolve
      final normalizedPath = p.normalize(file.absolute.path);
      final result = await resolveFile(path: normalizedPath);

      if (result is! ResolvedUnitResult) {
        throw StateError('Failed to resolve $normalizedPath');
      }

      // 3. Create Rule with MOCKS
      final rule = MockArchitectureRule(
        mockConfig: mockConfig,
        mockResolver: mockResolver,
      );

      await rule.testRun(result);
      return rule;
    }

    test('should delegate file resolution to FileResolver', () async {
      // Arrange
      const expectedComponent = ComponentConfig(id: 'mock_layer', path: 'any');

      // STUBBING: We don't care about real paths. We force the mock to return a component.
      when(() => mockResolver.resolve(any())).thenReturn(expectedComponent);

      // Act
      final rule = await runRule(relativePath: 'lib/main.dart');

      // Assert
      expect(rule.wasRunWithConfigCalled, isTrue);
      expect(rule.capturedComponent, expectedComponent);

      // Verify interaction
      verify(() => mockResolver.resolve(any())).called(1);
    });

    test('should pass null if FileResolver returns null', () async {
      // Arrange
      when(() => mockResolver.resolve(any())).thenReturn(null);

      // Act
      final rule = await runRule(relativePath: 'lib/unknown.dart');

      // Assert
      expect(rule.wasRunWithConfigCalled, isTrue);
      expect(rule.capturedComponent, isNull);
    });
  });
}