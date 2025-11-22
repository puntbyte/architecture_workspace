import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/error_handling/enforce_try_catch_in_repository.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceTryCatchInRepository Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('try_catch_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Define a DataSource interface in the correct directory structure
      // 'lib/features/user/data/sources/' -> ArchComponent.source
      addFile(
        'lib/features/user/data/sources/user_remote_source.dart',
        '''
        abstract class UserRemoteSource {
          Future<void> fetchUser();
        }
        ''',
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

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig();
      final lint = EnforceTryCatchInRepository(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when DataSource call is not wrapped in try-catch', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);

          Future<void> getUser() async {
            await source.fetchUser(); // VIOLATION
          }
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Calls to a DataSource must be wrapped'));
    });

    test('reports violation when DataSource call is in a finally block', () async {
      // Calling a risky method in finally is bad practice as it's not caught.
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);

          Future<void> getUser() async {
            try {
              print('hello');
            } catch(e) {
              // handle
            } finally {
              await source.fetchUser(); // VIOLATION
            }
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('reports violation when DataSource call is in a catch block', () async {
      // Calling a risky method in catch is also risky if not re-wrapped
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);

          Future<void> getUser() async {
            try {
              print('hello');
            } catch(e) {
              await source.fetchUser(); // VIOLATION
            }
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('does not report violation when DataSource call is safely wrapped', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);

          Future<void> getUser() async {
            try {
              await source.fetchUser(); // OK
            } catch (e) {
              // convert to Failure
            }
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('does not report violation for calls to non-DataSource objects', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        class OtherService {
          void doSafeWork() {}
        }
        
        class UserRepositoryImpl {
          final OtherService service;
          UserRepositoryImpl(this.service);

          void work() {
            service.doSafeWork(); // OK, not a data source
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('ignores files that are not repositories', () async {
      // UseCase calling source directly is bad architecture (layer violation), 
      // but THIS lint only checks repositories.
      final path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, '''
        import '../../data/sources/user_remote_source.dart';
        class GetUser {
          final UserRemoteSource source;
          GetUser(this.source);
          
          Future<void> call() async {
            await source.fetchUser(); 
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}