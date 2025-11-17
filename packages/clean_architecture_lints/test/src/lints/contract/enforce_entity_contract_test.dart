// test/src/lints/contract/enforce_entity_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_entity_contract.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_data.dart';

// Test helper to run the lint and capture results.
Future<List<LintCode>> runContractLint({
  required String source,
  required String path,
  required ArchitectureLintRule lint,
  required AnalysisContextCollection contextCollection,
}) async {
  final reporter = MockDiagnosticReporter();
  final resolver = MockCustomLintResolver();
  final context = MockCustomLintContext();
  final registry = MockLintRuleNodeRegistry();

  final capturedCodes = <LintCode>[];
  when(() => reporter.atToken(any(), any(), arguments: any(named: 'arguments'))).thenAnswer((
    invocation,
  ) {
    capturedCodes.add(invocation.positionalArguments[1] as LintCode);
  });

  when(() => resolver.source).thenReturn(FakeSource(fullName: path));
  when(() => context.registry).thenReturn(registry);

  void Function(ClassDeclaration)? capturedCallback;
  when(() => registry.addClassDeclaration(any())).thenAnswer((invocation) {
    capturedCallback = invocation.positionalArguments.first as void Function(ClassDeclaration);
  });

  lint.run(resolver, reporter, context);
  if (capturedCallback == null) return [];

  final unitResult =
      await contextCollection.contextFor(path).currentSession.getResolvedUnit(path)
          as ResolvedUnitResult;
  final classNodes = unitResult.unit.declarations.whereType<ClassDeclaration>();
  if (classNodes.isEmpty) throw StateError('No class found in test source');

  // We manually call the captured callback with the resolved node.
  capturedCallback!(classNodes.first);

  return capturedCodes;
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeToken());
    registerFallbackValue(FakeLintCode());
  });

  group('EnforceEntityContract Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectLib;

    // THE DEFINITIVE FIX: Define the helper at a scope accessible to all tests.
    void writeFile(String path, String content) {
      final file = resourceProvider.getFile(path);
      file.parent.create();
      file.writeAsStringSync(content);
    }

    setUpAll(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('entity_contract_test_');
      final projectPath = p.join(tempDir.path, 'test_project');
      projectLib = p.join(projectPath, 'lib');

      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(projectPath, '.dart_tool', 'package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );
      writeFile(p.join(projectLib, 'core', 'entity', 'entity.dart'), 'abstract class Entity {}');

      contextCollection = AnalysisContextCollection(
        includedPaths: [projectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDownAll(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('should report a violation when a concrete class does not extend Entity', () async {
      final config = makeConfig(entityDir: 'entities');
      final lint = EnforceEntityContract(config: config, layerResolver: LayerResolver(config));
      final path = p.join(projectLib, 'features', 'product', 'domain', 'entities', 'product.dart');
      const source = 'class Product {}';
      writeFile(path, source);

      final captured = await runContractLint(
        source: source,
        path: path,
        lint: lint,
        contextCollection: contextCollection,
      );
      expect(captured, hasLength(1));
    });

    test('should not report a violation when a class correctly extends Entity', () async {
      final config = makeConfig(entityDir: 'entities');
      final lint = EnforceEntityContract(config: config, layerResolver: LayerResolver(config));
      // Use unique path (order.dart) to avoid analyzer cache conflicts with other tests
      final path = p.join(projectLib, 'features', 'order', 'domain', 'entities', 'order.dart');
      const source = '''
        import 'package:test_project/core/entity/entity.dart';
        class Order extends Entity {}
      ''';
      writeFile(path, source);
      final captured = await runContractLint(
        source: source,
        path: path,
        lint: lint,
        contextCollection: contextCollection,
      );
      expect(captured, isEmpty);
    });

    test('should not report a violation for an abstract class', () async {
      final config = makeConfig(entityDir: 'entities');
      final lint = EnforceEntityContract(config: config, layerResolver: LayerResolver(config));
      final path = p.join(
        projectLib,
        'features',
        'shared',
        'domain',
        'entities',
        'base_entity.dart',
      );
      const source = 'abstract class BaseEntity {}';
      writeFile(path, source);
      final captured = await runContractLint(
        source: source,
        path: path,
        lint: lint,
        contextCollection: contextCollection,
      );
      expect(captured, isEmpty);
    });

    test('should stay silent when a custom inheritance rule for entities is defined', () async {
      final config = makeConfig(
        entityDir: 'entities',
        inheritanceRules: [
          {'on': 'entity'},
        ],
      );
      final lint = EnforceEntityContract(config: config, layerResolver: LayerResolver(config));
      final path = p.join(projectLib, 'features', 'custom', 'domain', 'entities', 'custom.dart');
      const source = 'class Custom {}';
      writeFile(path, source);
      final captured = await runContractLint(
        source: source,
        path: path,
        lint: lint,
        contextCollection: contextCollection,
      );
      expect(captured, isEmpty, reason: 'Should defer to the generic enforce_inheritance lint.');
    });
  });
}
