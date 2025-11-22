// test/src/lints/error_handling/disallow_throwing_from_repository_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/error_handling/'
    'disallow_throwing_from_repository.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowThrowingFromRepository Lint', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    // Helper to write files safely using canonical paths
    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      // [Windows Fix] Use canonical path
      tempDir = Directory.systemTemp.createTempSync('disallow_throwing_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
    });

    Future<List<Diagnostic>> runLint(String filePath) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(); // Uses default 'repositories' directory
      final lint = DisallowThrowingFromRepository(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when a throw expression is used in a method body', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
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

    test('reports violation when a throw expression is used in a lambda', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        class UserRepositoryImpl {
          void doSomething() => throw Exception('Failed');
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('does not report violation when no throw expression is present', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        class UserRepositoryImpl {
          int doSomething() {
            return 1;
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('does not report violation for a rethrow expression', () async {
      // NOTE: 'rethrow' is a RethrowExpression, not a ThrowExpression.
      // This test confirms we only strictly forbid explicitly initiating new exceptions.
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
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
      expect(lints, isEmpty);
    });

    test('ignores files that are not repositories', () async {
      // This file is in 'sources', so it should be identified as ArchComponent.source
      const path = 'lib/features/user/data/sources/user_remote_source.dart';
      addFile(path, '''
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
