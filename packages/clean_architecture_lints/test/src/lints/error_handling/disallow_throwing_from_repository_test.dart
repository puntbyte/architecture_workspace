// test/src/lints/error_handling/disallow_throwing_from_repository_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/error_handling/'
    'disallow_throwing_from_repository.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowThrowingFromRepository Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint(String filePath) async {
      final config = makeConfig(); // Uses default 'repositories' directory
      final lint = DisallowThrowingFromRepository(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final resolvedUnit =
          await contextCollection
                  .contextFor(p.normalize(filePath))
                  .currentSession
                  .getResolvedUnit(p.normalize(filePath))
              as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('disallow_throwing_test_');
      projectPath = p.normalize(tempDir.path);
      final testProjectPath = p.join(projectPath, 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    String testProjectPath() => p.join(projectPath, 'test_project');

    test('should report violation when a throw expression is used in a method body', () async {
      final path = p.join(
        testProjectPath(),
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        class UserRepositoryImpl {
          void doSomething() {
            throw Exception('Failed');
          }
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'disallow_throwing_from_repository');
    });

    test('should report violation when a throw expression is used in a lambda', () async {
      final path = p.join(
        testProjectPath(),
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        class UserRepositoryImpl {
          void doSomething() => throw Exception('Failed');
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('should not report violation when no throw expression is present', () async {
      final path = p.join(
        testProjectPath(),
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        class UserRepositoryImpl {
          int doSomething() {
            return 1;
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should not report violation for a rethrow expression', () async {
      final path = p.join(
        testProjectPath(),
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        class UserRepositoryImpl {
          void doSomething() {
            try {
              // some operation
            } catch (e) {
              rethrow;
            }
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty, reason: 'Rethrow is a different expression and should be allowed.');
    });

    test('should not report violation when throw is used in a non-repository file', () async {
      // This file is in a 'sources' directory, not 'repositories'.
      final path = p.join(
        testProjectPath(),
        'lib/features/user/data/sources/user_remote_source.dart',
      );
      writeFile(path, '''
        class UserRemoteSource {
          void doSomething() {
            throw Exception('API Failed');
          }
        }
      ''');

      final lints = await runLint(path);
      expect(
        lints,
        isEmpty,
        reason: 'Lint should only run on files identified as repository implementations.',
      );
    });
  });
}
