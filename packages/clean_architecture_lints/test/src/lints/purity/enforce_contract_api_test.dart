import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/purity/enforce_contract_api.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceContractApi Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint(String filePath) async {
      final config = makeConfig();
      final lint = EnforceContractApi(config: config, layerResolver: LayerResolver(config));

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
      tempDir = Directory.systemTemp.createTempSync('enforce_contract_api_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(testProjectPath, '.dart_tool/package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );

      // Define the contract (Port) that implementations should adhere to.
      writeFile(
        p.join(testProjectPath, 'lib/features/user/domain/ports/user_repository.dart'),
        '''
        abstract class UserRepository {
          void fetchUser(String id);
          String get userName;
        }
        ''',
      );

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation for a public method not in the contract', () async {
      final path = p.join(
        testProjectPath,
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {
          @override
          void fetchUser(String id) {}

          @override
          String get userName => 'test';
          
          void publicHelper() {} // VIOLATION
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'The public member `publicHelper` is not defined in the interface contract.',
      );
    });

    test('should report violation for a public field not in the contract', () async {
      final path = p.join(
        testProjectPath,
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {
          final String publicField = 'oops'; // VIOLATION (implicit public getter)
          
          @override
          void fetchUser(String id) {}

          @override
          String get userName => publicField;
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('should not report violation for members that are in the contract', () async {
      final path = p.join(
        testProjectPath,
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {
          @override
          void fetchUser(String id) {}

          @override
          String get userName => 'test';
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should not report violation for private members', () async {
      final path = p.join(
        testProjectPath,
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {
          @override
          void fetchUser(String id) => _privateHelper();

          @override
          String get userName => 'test';
          
          void _privateHelper() {} // OK
          final String _privateField = ''; // OK
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should not report violation for constructors', () async {
      final path = p.join(
        testProjectPath,
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {
          UserRepositoryImpl(); // OK
          
          @override
          void fetchUser(String id) {}

          @override
          String get userName => 'test';
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}
