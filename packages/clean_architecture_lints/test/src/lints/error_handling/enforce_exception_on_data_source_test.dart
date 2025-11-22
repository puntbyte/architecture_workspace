// test/src/lints/error_handling/enforce_exception_on_data_source_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/error_handling/enforce_exception_on_data_source.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceExceptionOnDataSource Lint', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('enforce_exception_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Define the "safe type" that should be forbidden in DataSources.
      addFile('lib/core/either.dart', 'class Either<L, R> {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? typeSafeties,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(typeSafeties: typeSafeties);
      final lint = EnforceExceptionOnDataSource(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    // The type safety config that defines `Either` as a "safe" type (wrapper).
    // This implies it is FORBIDDEN in DataSources.
    final typeSafetyConfig = [
      {
        'on': ['usecase'],
        'returns': {
          'unsafe_type': 'Future',
          'safe_type': 'Either',
          'import': 'package:test_project/core/either.dart',
        },
      },
    ];

    test('reports violation when a data source interface returns a forbidden wrapper type', () async {
      final path = 'lib/features/user/data/sources/user_source.dart';
      addFile(path, '''
        import 'package:test_project/core/either.dart';
        abstract class UserSource {
          Future<Either<Exception, bool>> login();
        }
      ''');

      final lints = await runLint(filePath: path, typeSafeties: typeSafetyConfig);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('DataSources should throw exceptions on failure'));
    });

    test('reports violation when a data source implementation returns a forbidden wrapper type', () async {
      final path = 'lib/features/user/data/sources/user_source_impl.dart';
      addFile(path, '''
        import 'package:test_project/core/either.dart';
        class UserSourceImpl {
          Either<Exception, bool> login() => throw UnimplementedError();
        }
      ''');

      final lints = await runLint(filePath: path, typeSafeties: typeSafetyConfig);
      expect(lints, hasLength(1));
    });

    test('does not report violation when a data source returns a simple type', () async {
      final path = 'lib/features/user/data/sources/user_source.dart';
      addFile(path, '''
        abstract class UserSource {
          Future<String> getToken();
        }
      ''');

      final lints = await runLint(filePath: path, typeSafeties: typeSafetyConfig);
      expect(lints, isEmpty);
    });

    test('does not report violation when type_safeties config is empty', () async {
      final path = 'lib/features/user/data/sources/user_source.dart';
      addFile(path, '''
        import 'package:test_project/core/either.dart';
        abstract class UserSource {
          Future<Either<Exception, bool>> login();
        }
      ''');

      final lints = await runLint(filePath: path, typeSafeties: []);
      expect(lints, isEmpty);
    });

    test('ignores files that are not DataSources (e.g. Repositories)', () async {
      final path = 'lib/features/user/data/repositories/user_repository.dart';
      addFile(path, '''
        import 'package:test_project/core/either.dart';
        class UserRepository {
          Future<Either<Exception, bool>> login() async => throw UnimplementedError();
        }
      ''');

      final lints = await runLint(filePath: path, typeSafeties: typeSafetyConfig);
      expect(lints, isEmpty);
    });
  });
}