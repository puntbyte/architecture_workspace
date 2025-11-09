// test/src/lints/enforce_type_safety_feature_first_example_test.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_kit/src/lints/structure/enforce_type_safety.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/models/type_safety_config.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

/// Helper to run the lint like custom_lint would: capture addMethodDeclaration
/// and invoke it for each MethodDeclaration found in the parsed AST.
Future<List<dynamic>> _runLintAndCapture(
    EnforceTypeSafety lint,
    String filePath,
    String source,
    MockDiagnosticReporter reporter,
    ) async {
  final resolver = MockCustomLintResolver();
  final context = MockCustomLintContext();
  final registry = MockLintRuleNodeRegistry();

  when(() => resolver.source).thenReturn(FakeSource(fullName: filePath));
  when(() => context.registry).thenReturn(registry);

  void Function(MethodDeclaration)? capturedCallback;
  when(() => registry.addMethodDeclaration(any())).thenAnswer((invocation) {
    capturedCallback = invocation.positionalArguments.first as void Function(MethodDeclaration);
  });

  // Capture reporter calls
  final captured = <dynamic>[];
  // Capture atNode calls
  when(() => reporter.atNode(any(), any())).thenAnswer((invocation) {
    captured.add({'fn': 'atNode', 'node': invocation.positionalArguments[0], 'code': invocation.positionalArguments[1]});
    return null;
  });
  when(() => reporter.atToken(any(), any())).thenAnswer((invocation) {
    captured.add({'fn': 'atToken', 'token': invocation.positionalArguments[0], 'code': invocation.positionalArguments[1]});
    return null;
  });

  // Register visitor
  lint.run(resolver, reporter, context);

  expect(capturedCallback, isNotNull, reason: 'lint did not register addMethodDeclaration (no visitor captured)');

  // Parse and invoke captured callback on each method
  final parsed = parseString(content: source, path: filePath, throwIfDiagnostics: false);
  for (final classDecl in parsed.unit.declarations.whereType<ClassDeclaration>()) {
    for (final m in classDecl.members.whereType<MethodDeclaration>()) {
      capturedCallback!(m);
    }
  }

  return captured;
}

void main() {
  setUpAll(() {
    // real AST fallback registrations (if your other tests rely on them)
    registerFallbackValue(FakeToken());
    registerFallbackValue(FakeLintCode());

    // create concrete AST fallback instances so mocktail's any() works for AstNode/TypeAnnotation/SimpleIdentifier
    final parsed = parseString(content: 'class _D { void m(String id) {} }', throwIfDiagnostics: false);
    final unit = parsed.unit;
    final classDecl = unit.declarations.whereType<ClassDeclaration>().first;
    final method = classDecl.members.whereType<MethodDeclaration>().first;
    final param = method.parameters!.parameters.first;
    final typeNode = (param as SimpleFormalParameter).type!;
    final simpleId = classDecl.name;

    registerFallbackValue(unit); // AstNode
    registerFallbackValue(typeNode); // TypeAnnotation
    registerFallbackValue(simpleId); // SimpleIdentifier
  });

  group('EnforceTypeSafety feature-first example', () {
    late Directory tmp;
    late String projectRoot;
    late MockDiagnosticReporter reporter;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('enforce_type_safety_feat_');
      projectRoot = tmp.path;
      await File(p.join(projectRoot, 'pubspec.yaml')).writeAsString('name: tmp_pkg');
      reporter = MockDiagnosticReporter();
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    test('example file under lib/features/... should be flagged for wrong return type', () async {
      // Prepare a feature-first CleanArchitectureConfig where repositories dir is "contracts"
      final map = {
        'project_structure': 'feature_first',
        'feature_first_paths': {'features_root': 'features'},
        'layer_definitions': {
          'domain': {
            'repositories': ['contracts'],
            'usecases': ['usecases'],
          }
        },
        'type_safety': {
          'returns': [
            {'type': 'FutureEither', 'where': ['domain_repository']}
          ],
        },
      };
      final fullConfig = CleanArchitectureConfig.fromMap(map);

      final lint = EnforceTypeSafety(config: fullConfig, layerResolver: LayerResolver(fullConfig));

      // Create the example file under lib/features/auth/domain/contracts/...
      final repoPath = p.join(projectRoot, 'lib', 'features', 'auth', 'domain', 'contracts', 'bad_return_repository.dart');
      await File(repoPath).parent.create(recursive: true);

      const source = '''
        abstract interface class BadReturnTypeRepository implements Repository {
          // VIOLATION: enforce_type_safety (returns Future instead of FutureEither)
          Future<User> getUser(int id);
        }
      ''';
      await File(repoPath).writeAsString(source);

      // Double-check resolver resolution and config
      final resolver = LayerResolver(fullConfig);
      final sub = resolver.getSubLayer(repoPath);
      expect(sub, ArchSubLayer.domainRepository, reason: 'LayerResolver did not resolve file to domainRepository; actual: $sub');

      expect(fullConfig.typeSafety.returns, isNotEmpty, reason: 'typeSafety returns rules not loaded from config');
      expect(fullConfig.typeSafety.returns.first.type, 'FutureEither');

      // Run the lint and capture calls
      final captured = await _runLintAndCapture(lint, repoPath, source, reporter);

      // If the rule applied, we should have at least one reporter call (atNode or atToken)
      expect(captured, isNotEmpty, reason: 'EnforceTypeSafety did not report for the example file. Captured list empty.');

      // Inspect the first captured entry and its LintCode/problemMessage (dynamic-safe)
      final first = captured.first as Map;
      expect(first['code'], isNotNull);

      // Safely extract message:
      final codeObj = first['code'];
      String messageLower = codeObj?.toString().toLowerCase() ?? '';
      // If it has a 'problemMessage' field, prefer that
      try {
        final dyn = codeObj as dynamic;
        final pm = dyn.problemMessage;
        if (pm != null) {
          messageLower = pm.toString().toLowerCase();
        }
      } catch (_) {
        // ignore, we already have toString()
      }

      // The message should mention 'futureeither' or at least 'future'
      final ok = messageLower.contains('futureeither') || messageLower.contains('future');
      expect(ok, isTrue, reason: 'Reported lint message does not mention FutureEither or Future. actual: $messageLower');
    });
  });
}
