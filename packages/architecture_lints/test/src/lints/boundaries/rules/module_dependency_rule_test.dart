import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:architecture_lints/src/lints/boundaries/rules/module_dependency_rule.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/mocks.dart';

// Wrapper to expose protected checkImport method
class TestModuleDependencyRule extends ModuleDependencyRule {}

// Dummy node for fallback
AstNode _createDummyNode() {
  return parseString(content: '// dummy').unit;
}

void main() {
  group('ModuleDependencyRule', () {
    late TestModuleDependencyRule rule;
    late MockDiagnosticReporter mockReporter;
    late MockCustomLintResolver mockResolver;
    late FakeCustomLintContext fakeContext;
    late MockFileResolver mockFileResolver;

    setUpAll(() {
      registerFallbackValue(_createDummyNode());
      registerFallbackValue(FakeLintCode());
    });

    setUp(() {
      rule = TestModuleDependencyRule();
      mockReporter = MockDiagnosticReporter();
      mockResolver = MockCustomLintResolver();
      fakeContext = FakeCustomLintContext();
      mockFileResolver = MockFileResolver();

      when(() => mockReporter.atNode(
        any(),
        any(),
        arguments: any(named: 'arguments'),
        contextMessages: any(named: 'contextMessages'),
        data: any(named: 'data'),
      )).thenReturn(MockDiagnostic());
    });

    // --- Helpers ---

    ImportDirective createImportNode(String uri) {
      final result = parseString(content: "import '$uri';");
      return result.unit.directives.first as ImportDirective;
    }

    ArchitectureConfig createConfig() {
      return const ArchitectureConfig(
        components: [],
        modules: [
          // Strict Feature Module (default strict=true if wildcard used)
          ModuleConfig(
            key: 'feature',
            path: r'features/${name}',
            strict: true,
          ),
          // Shared Module (Not strict isolation between siblings usually, but let's test strict logic)
          ModuleConfig(
            key: 'core',
            path: 'core',
            strict: false,
          ),
        ],
      );
    }

    test('should report error when Feature A imports Feature B', () {
      final config = createConfig();

      // Current File: features/auth
      const currentPath = 'lib/features/auth/domain/login.dart';
      when(() => mockResolver.path).thenReturn(currentPath);

      // Imported File: features/home
      const importedPath = 'lib/features/home/domain/dashboard.dart';
      const importUri = 'package:app/features/home/domain/dashboard.dart';

      // Mock resolution (component can be null if not configured, module logic handles it)
      when(() => mockFileResolver.resolve(importedPath)).thenReturn(null);

      final node = createImportNode(importUri);

      rule.checkImport(
        node: node,
        uri: importUri,
        importedPath: importedPath,
        config: config,
        fileResolver: mockFileResolver,
        component: null, // Let rule resolve module manually
        reporter: mockReporter,
        resolver: mockResolver,
        context: fakeContext,
      );

      // Expect Error: Feature "auth" cannot import Feature "home"
      final captured = verify(() => mockReporter.atNode(
        any(), // node.uri
        any(), // LintCode
        arguments: captureAny(named: 'arguments'),
      )).captured;

      expect(captured.length, 1);
      final args = captured.first as List;
      expect(args[0], 'Feature'); // Module Type
      expect(args[1], 'auth');    // Current Instance
      expect(args[2], 'home');    // Imported Instance
    });

    test('should PASS when Feature A imports Core', () {
      final config = createConfig();

      // Current: features/auth
      const currentPath = 'lib/features/auth/domain/login.dart';
      when(() => mockResolver.path).thenReturn(currentPath);

      // Import: core
      const importedPath = 'lib/core/error/failure.dart';
      const importUri = 'package:app/core/error/failure.dart';
      when(() => mockFileResolver.resolve(importedPath)).thenReturn(null);

      final node = createImportNode(importUri);

      rule.checkImport(
        node: node,
        uri: importUri,
        importedPath: importedPath,
        config: config,
        fileResolver: mockFileResolver,
        component: null,
        reporter: mockReporter,
        resolver: mockResolver,
        context: fakeContext,
      );

      verifyNever(() => mockReporter.atNode(any(), any(), arguments: any(named: 'arguments')));
    });

    test('should PASS when Feature A imports Feature A (Self)', () {
      final config = createConfig();

      // Current: features/auth
      const currentPath = 'lib/features/auth/presentation/page.dart';
      when(() => mockResolver.path).thenReturn(currentPath);

      // Import: features/auth (Logic)
      const importedPath = 'lib/features/auth/presentation/bloc.dart';
      const importUri = '../bloc.dart';
      when(() => mockFileResolver.resolve(importedPath)).thenReturn(null);

      final node = createImportNode(importUri);

      rule.checkImport(
        node: node,
        uri: importUri,
        importedPath: importedPath,
        config: config,
        fileResolver: mockFileResolver,
        component: null,
        reporter: mockReporter,
        resolver: mockResolver,
        context: fakeContext,
      );

      verifyNever(() => mockReporter.atNode(any(), any(), arguments: any(named: 'arguments')));
    });

    test('should PASS if module is NOT strict', () {
      const config = ArchitectureConfig(
        components: [],
        modules: [
          // Non-strict features
          const ModuleConfig(
            key: 'feature',
            path: r'features/${name}',
            strict: false,
          ),
        ],
      );

      const currentPath = 'lib/features/auth/a.dart';
      when(() => mockResolver.path).thenReturn(currentPath);

      const importedPath = 'lib/features/home/b.dart';
      const importUri = 'package:app/features/home/b.dart';
      when(() => mockFileResolver.resolve(importedPath)).thenReturn(null);

      final node = createImportNode(importUri);

      rule.checkImport(
        node: node,
        uri: importUri,
        importedPath: importedPath,
        config: config,
        fileResolver: mockFileResolver,
        component: null,
        reporter: mockReporter,
        resolver: mockResolver,
        context: fakeContext,
      );

      verifyNever(() => mockReporter.atNode(any(), any(), arguments: any(named: 'arguments')));
    });
  });
}
