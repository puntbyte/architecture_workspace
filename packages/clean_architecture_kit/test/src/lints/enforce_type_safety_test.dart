// test/src/lints/enforce_type_safety_test.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:clean_architecture_kit/src/lints/enforce_type_safety.dart';
import 'package:clean_architecture_kit/src/models/type_safety_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

/// Helper to run the lint similarly to how custom_lint would invoke it:
/// - registers the visitor via `run(...)` and captures the `addMethodDeclaration` callback.
/// - parses the provided source and invokes the captured callback for each MethodDeclaration.
Future<void> runEnforceTypeSafetyLint({
  required EnforceTypeSafety lint,
  required MockDiagnosticReporter reporter,
  required String filePath,
  required String source,
}) async {
  final resolver = MockCustomLintResolver();
  final context = MockCustomLintContext();
  final registry = MockLintRuleNodeRegistry();

  when(() => resolver.source).thenReturn(FakeSource(fullName: filePath));
  when(() => context.registry).thenReturn(registry);

  void Function(MethodDeclaration)? capturedCallback;
  when(() => registry.addMethodDeclaration(any())).thenAnswer((invocation) {
    capturedCallback = invocation.positionalArguments.first as void Function(MethodDeclaration);
  });

  // Register visitor
  lint.run(resolver, reporter, context);

  // Parse and invoke the captured callback for each MethodDeclaration
  final parsed = parseString(content: source, path: filePath, throwIfDiagnostics: false);
  final unit = parsed.unit;

  expect(capturedCallback, isNotNull, reason: 'Expected addMethodDeclaration to be called.');

  for (final classDecl in unit.declarations.whereType<ClassDeclaration>()) {
    for (final method in classDecl.members.whereType<MethodDeclaration>()) {
      capturedCallback!(method);
    }
  }
}

void main() {
  setUpAll(() {
    // Keep existing fakes for Token & LintCode
    registerFallbackValue(FakeToken());
    registerFallbackValue(FakeLintCode());

    // Create concrete AST instances to register as mocktail fallback values.
    // We parse a tiny snippet and extract objects to use as safe fallback values
    // for types that are sealed/final in analyzer.
    final parsed = parseString(
      content: r'''
        // tiny snippet used only to construct AST fallback nodes
        class _Dummy {
          void method(String id) {}
          set value(String v) {}
        }
      ''',
      throwIfDiagnostics: false,
    );

    final unit = parsed.unit; // CompilationUnit implements AstNode
    final classDecl = unit.declarations.whereType<ClassDeclaration>().first;
    final method = classDecl.members.whereType<MethodDeclaration>().first;
    final param = method.parameters!.parameters.first;
    final typeNode = (param as SimpleFormalParameter).type!; // TypeAnnotation
    final simpleIdent = classDecl.name; // SimpleIdentifier

    // Register concrete instances as fallback values.
    registerFallbackValue(unit); // AstNode
    registerFallbackValue(typeNode); // TypeAnnotation
    registerFallbackValue(simpleIdent); // SimpleIdentifier
  });

  group('EnforceTypeSafety lint', () {
    late Directory tmp;
    late String projectRoot;
    late MockDiagnosticReporter reporter;

    setUp(() async {
      reporter = MockDiagnosticReporter();
      tmp = await Directory.systemTemp.createTemp('enforce_type_safety_test_');
      projectRoot = tmp.path;

      // Create pubspec so PathUtils.findProjectRoot() can discover the project root (if used).
      await File(p.join(projectRoot, 'pubspec.yaml')).writeAsString('name: test_project');
    });

    tearDown(() async {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    });

    test('reports when return type is missing but a return rule applies', () async {
      final returnRule = ReturnRule(type: 'FutureEither', where: ['domain_repository']);
      final config = makeLayerFirstConfig(returnRules: [returnRule]);
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));

      final repoPath = p.join(projectRoot, 'lib', 'domain', 'repositories', 'user_repository.dart');
      await File(repoPath).parent.create(recursive: true);

      const src = '''
        abstract class UserRepository {
          fetchUser();
        }
      ''';
      await File(repoPath).writeAsString(src);

      await runEnforceTypeSafetyLint(
        lint: lint,
        reporter: reporter,
        filePath: repoPath,
        source: src,
      );

      verify(() => reporter.atToken(any(), any())).called(1);
    });

    test('reports when return type does not start with expected type', () async {
      final returnRule = ReturnRule(type: 'FutureEither', where: ['domain_repository']);
      final config = makeLayerFirstConfig(returnRules: [returnRule]);
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));

      final repoPath = p.join(projectRoot, 'lib', 'domain', 'repositories', 'user_repository.dart');
      await File(repoPath).parent.create(recursive: true);

      const src = '''
        abstract class UserRepository {
          String fetchUser();
        }
      ''';
      await File(repoPath).writeAsString(src);

      await runEnforceTypeSafetyLint(
        lint: lint,
        reporter: reporter,
        filePath: repoPath,
        source: src,
      );

      // atNode should be called for incorrect return type
      verify(() => reporter.atNode(any(), any())).called(greaterThanOrEqualTo(1));
    });

    test('reports when parameter identified by identifier has wrong type', () async {
      final paramRule = ParameterRule(type: 'Id', where: ['domain_repository'], identifier: 'id');
      final config = makeLayerFirstConfig(parameterRules: [paramRule]);
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));

      final repoPath = p.join(projectRoot, 'lib', 'domain', 'repositories', 'user_repository.dart');
      await File(repoPath).parent.create(recursive: true);

      const src = '''
        abstract class UserRepository {
          void getUser(int id);
        }
      ''';
      await File(repoPath).writeAsString(src);

      await runEnforceTypeSafetyLint(
        lint: lint,
        reporter: reporter,
        filePath: repoPath,
        source: src,
      );

      verify(() => reporter.atNode(any(), any())).called(greaterThanOrEqualTo(1));
    });

    test('does NOT report when setter is encountered (skipped by rule)', () async {
      final returnRule = ReturnRule(type: 'FutureEither', where: ['domain_repository']);
      final config = makeLayerFirstConfig(returnRules: [returnRule]);
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));

      final repoPath = p.join(projectRoot, 'lib', 'domain', 'repositories', 'settings.dart');
      await File(repoPath).parent.create(recursive: true);

      const src = '''
        abstract class Settings {
          set value(String v);
        }
      ''';
      await File(repoPath).writeAsString(src);

      await runEnforceTypeSafetyLint(
        lint: lint,
        reporter: reporter,
        filePath: repoPath,
        source: src,
      );

      // should not report
      verifyNever(() => reporter.atToken(any(), any()));
      verifyNever(() => reporter.atNode(any(), any()));
    });

    test('does NOT report when parameter name does not match identifier', () async {
      final paramRule = ParameterRule(type: 'Id', where: ['domain_repository'], identifier: 'id');
      final config = makeLayerFirstConfig(parameterRules: [paramRule]);
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));

      final repoPath = p.join(projectRoot, 'lib', 'domain', 'repositories', 'user_repository.dart');
      await File(repoPath).parent.create(recursive: true);

      const src = '''
        abstract class UserRepository {
          void getUser(String user);
        }
      ''';
      await File(repoPath).writeAsString(src);

      await runEnforceTypeSafetyLint(
        lint: lint,
        reporter: reporter,
        filePath: repoPath,
        source: src,
      );

      verifyNever(() => reporter.atNode(any(), any()));
      verifyNever(() => reporter.atToken(any(), any()));
    });
  });
}
