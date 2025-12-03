import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/core/resolver/import_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ImportResolver', () {
    late Directory tempDir;
    late String projectPath;
    late AnalysisContextCollection contextCollection;

    // Helper to write files to the temp project
    void addFile(String relativePath, String content) {
      final fullPath = p.join(projectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    // Helper to resolve a file using the real Analyzer
    Future<ResolvedUnitResult> resolveFile(String relativePath) async {
      final fullPath = p.normalize(p.join(projectPath, relativePath));

      // Re-create collection if new files were added (basic handling for tests)
      contextCollection = AnalysisContextCollection(includedPaths: [projectPath]);

      final context = contextCollection.contextFor(fullPath);
      final result = await context.currentSession.getResolvedUnit(fullPath);

      if (result is! ResolvedUnitResult) {
        throw StateError('Failed to resolve file: $fullPath');
      }
      return result;
    }

    // Helper to find a specific import directive in the AST
    ImportDirective findImportDirective(ResolvedUnitResult unit, String uriText) {
      return unit.unit.directives
          .whereType<ImportDirective>()
          .firstWhere(
            (d) => d.uri.stringValue == uriText,
        orElse: () => throw StateError('Import "$uriText" not found in ${unit.path}'),
      );
    }

    setUp(() {
      // 1. Create a temporary directory for the test project
      tempDir = Directory.systemTemp.createTempSync('import_resolver_test_');
      projectPath = p.canonicalize(tempDir.path);

      // 2. Create pubspec.yaml
      addFile('pubspec.yaml', 'name: test_project');

      // 3. Create package_config.json to simulate a real package structure
      // This tells the analyzer that "package:test_project" maps to the "lib" folder.
      final libUri = p.toUri(p.join(projectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [
          {
            "name": "test_project",
            "rootUri": "$libUri",
            "packageUri": "."
          }
        ]
      }
      ''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should resolve relative import to absolute file path', () async {
      // Arrange
      addFile('lib/feature/domain/entity.dart', 'class Entity {}');
      addFile('lib/feature/domain/usecase.dart', "import 'entity.dart';");

      // Act
      final result = await resolveFile('lib/feature/domain/usecase.dart');
      final directive = findImportDirective(result, 'entity.dart');
      final resolvedPath = ImportResolver.resolvePath(node: directive);

      // Assert
      final expectedPath = p.join(projectPath, 'lib', 'feature', 'domain', 'entity.dart');
      expect(resolvedPath, equals(p.normalize(expectedPath)));
    });

    test('should resolve parent relative import (../) to absolute file path', () async {
      // Arrange
      addFile('lib/core/utils.dart', 'class Utils {}');
      addFile('lib/feature/data/repo.dart', "import '../../core/utils.dart';");

      // Act
      final result = await resolveFile('lib/feature/data/repo.dart');
      final directive = findImportDirective(result, '../../core/utils.dart');
      final resolvedPath = ImportResolver.resolvePath(node: directive);

      // Assert
      final expectedPath = p.join(projectPath, 'lib', 'core', 'utils.dart');
      expect(resolvedPath, equals(p.normalize(expectedPath)));
    });

    test('should resolve internal package import to absolute file path', () async {
      // Arrange
      addFile('lib/shared/model.dart', 'class Model {}');
      addFile('lib/main.dart', "import 'package:test_project/shared/model.dart';");

      // Act
      final result = await resolveFile('lib/main.dart');
      final directive = findImportDirective(result, 'package:test_project/shared/model.dart');
      final resolvedPath = ImportResolver.resolvePath(node: directive);

      // Assert
      final expectedPath = p.join(projectPath, 'lib', 'shared', 'model.dart');
      expect(resolvedPath, equals(p.normalize(expectedPath)));
    });

    test('should return null for dart: imports', () async {
      // Arrange
      addFile('lib/main.dart', "import 'dart:io';");

      // Act
      final result = await resolveFile('lib/main.dart');
      final directive = findImportDirective(result, 'dart:io');
      final resolvedPath = ImportResolver.resolvePath(node: directive);

      // Assert
      expect(resolvedPath, isNull);
    });

    test('should return null for unresolved imports (file does not exist)', () async {
      // Arrange
      addFile('lib/main.dart', "import 'missing_file.dart';");

      // Act
      final result = await resolveFile('lib/main.dart');
      final directive = findImportDirective(result, 'missing_file.dart');
      final resolvedPath = ImportResolver.resolvePath(node: directive);

      // Assert
      expect(resolvedPath, isNull);
    });
  });
}