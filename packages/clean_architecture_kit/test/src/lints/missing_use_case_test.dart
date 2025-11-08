// test/src/lints/missing_use_case_test.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_kit/src/lints/missing_use_case.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/path_utils.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

Future<void> runMissingUseCaseLint({
  required String repoSource,
  required String repoPath,
  required MissingUseCase lint,
  required MockDiagnosticReporter reporter,
}) async {
  final resolver = MockCustomLintResolver();
  final context = MockCustomLintContext();
  final registry = MockLintRuleNodeRegistry();

  when(() => resolver.source).thenReturn(FakeSource(fullName: repoPath));
  when(() => context.registry).thenReturn(registry);

  void Function(ClassDeclaration)? capturedCallback;
  when(() => registry.addClassDeclaration(any())).thenAnswer((invocation) {
    capturedCallback = invocation.positionalArguments.first as void Function(ClassDeclaration);
  });

  // Act 1: register visitor
  lint.run(resolver, reporter, context);

  // Act 2: parse file and invoke the captured visitor
  final parsed = parseString(content: repoSource, path: repoPath, throwIfDiagnostics: false);
  final classNode = parsed.unit.declarations.whereType<ClassDeclaration>().first;

  expect(
    capturedCallback,
    isNotNull,
    reason: 'addClassDeclaration was never called by the lint.',
  );

  capturedCallback!(classNode);
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeToken());
    registerFallbackValue(FakeLintCode());
  });

  group('MissingUseCase Lint', () {
    late Directory tmp;
    late String projectRoot;
    late MockDiagnosticReporter reporter;

    setUp(() async {
      reporter = MockDiagnosticReporter();
      tmp = await Directory.systemTemp.createTemp('missing_use_case_test_');
      projectRoot = tmp.path;
      await File(p.join(projectRoot, 'pubspec.yaml')).writeAsString('name: test_project');
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    // We'll test both layouts: layer-first and feature-first.
    <String, CleanArchitectureConfig Function()>{
      'layer_first': () => makeLayerFirstConfig(
        domainRepositoriesPaths: ['repositories'],
        useCasesPaths: ['usecases'],
      ),
      'feature_first': () => makeFeatureFirstConfig(
        featuresRoot: 'features',
        domainRepositoriesPaths: ['contracts'],
        useCasesPaths: ['usecases'],
      ),
    }.forEach((layoutName, configFactory) {
      group('project layout: $layoutName', () {
        test('should report a violation when the corresponding use case file is missing', () async {
          final config = configFactory();
          final lint = MissingUseCase(config: config, layerResolver: LayerResolver(config));

          // Decide repo path depending on layout
          final repoPath = layoutName == 'layer_first'
              ? p.join(projectRoot, 'lib', 'domain', 'repositories', 'user_repository.dart')
              : p.join(
                  projectRoot,
                  'lib',
                  'features',
                  'users',
                  'domain',
                  'contracts',
                  'user_repository.dart',
                );

          // Ensure directories exist
          await File(repoPath).parent.create(recursive: true);

          const repoSource = '''
            abstract interface class UserRepository {
              void fetchUser();
            }
          ''';
          await File(repoPath).writeAsString(repoSource);

          await runMissingUseCaseLint(
            repoSource: repoSource,
            repoPath: repoPath,
            lint: lint,
            reporter: reporter,
          );

          verify(() => reporter.atToken(any(), any())).called(1);
        });

        test('should NOT report a violation when the corresponding use case file exists', () async {
          final config = configFactory();
          final lint = MissingUseCase(config: config, layerResolver: LayerResolver(config));

          final repoPath = layoutName == 'layer_first'
              ? p.join(projectRoot, 'lib', 'domain', 'repositories', 'user_repository.dart')
              : p.join(
                  projectRoot,
                  'lib',
                  'features',
                  'users',
                  'domain',
                  'contracts',
                  'user_repository.dart',
                );

          // Ensure repo file exists
          await File(repoPath).parent.create(recursive: true);
          const repoSource = '''
            abstract interface class UserRepository {
              void fetchUser();
            }
          ''';
          await File(repoPath).writeAsString(repoSource);

          // Compute expected use case path using PathUtils to avoid fragile assumptions
          final expectedUseCasePath = PathUtils.getUseCaseFilePath(
            methodName: 'fetchUser',
            repoPath: repoPath,
            config: config,
          );

          expect(
            expectedUseCasePath,
            isNotNull,
            reason: 'Expected use case path should be resolvable.',
          );

          final useCaseFile = File(expectedUseCasePath!);
          await useCaseFile.create(recursive: true);
          await useCaseFile.writeAsString('// Usecase exists');

          await runMissingUseCaseLint(
            repoSource: repoSource,
            repoPath: repoPath,
            lint: lint,
            reporter: reporter,
          );

          verifyNever(() => reporter.atToken(any(), any()));
        });

        test('should ignore private methods', () async {
          final config = configFactory();
          final lint = MissingUseCase(config: config, layerResolver: LayerResolver(config));

          final repoPath = layoutName == 'layer_first'
              ? p.join(projectRoot, 'lib', 'domain', 'repositories', 'user_repository.dart')
              : p.join(
                  projectRoot,
                  'lib',
                  'features',
                  'users',
                  'domain',
                  'contracts',
                  'user_repository.dart',
                );

          await File(repoPath).parent.create(recursive: true);
          const repoSource = '''
            abstract interface class UserRepository {
              void _internalHelper();
            }
          ''';
          await File(repoPath).writeAsString(repoSource);

          await runMissingUseCaseLint(
            repoSource: repoSource,
            repoPath: repoPath,
            lint: lint,
            reporter: reporter,
          );

          verifyNever(() => reporter.atToken(any(), any()));
        });
      });
    });
  });
}
