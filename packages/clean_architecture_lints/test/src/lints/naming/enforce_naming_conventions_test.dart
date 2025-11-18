// test/srcs/lints/naming/enforce_naming_conventions_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/naming/enforce_naming_conventions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceNamingConventions Lint', () {
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

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> namingRules,
    }) async {
      final config = makeConfig(namingRules: namingRules);
      final lint = EnforceNamingConventions(config: config, layerResolver: LayerResolver(config));

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
      tempDir = Directory.systemTemp.createTempSync('naming_conventions_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when class name does not match the required pattern', () async {
      final path = p.join(testProjectPath, 'lib/features/user/data/models/user.dart');
      writeFile(path, 'class User {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'model', 'pattern': '{{name}}Model'},
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_naming_conventions_pattern');
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'The name `User` does not match the required `{{name}}Model` convention for a Model.',
      );
    });

    test('should report violation when class name matches a forbidden anti-pattern', () async {
      final path = p.join(testProjectPath, 'lib/features/user/domain/entities/user_entity.dart');
      writeFile(path, 'class UserEntity {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'entity', 'pattern': '{{name}}', 'antipattern': '{{name}}Entity'},
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_naming_conventions_antipattern');
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'The name `UserEntity` uses a forbidden pattern for a Entity.',
      );
    });

    test('should not report violation when class name follows all conventions', () async {
      final path = p.join(testProjectPath, 'lib/features/user/data/models/user_model.dart');
      writeFile(path, 'class UserModel {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'model', 'pattern': '{{name}}Model'},
        ],
      );
      expect(lints, isEmpty);
    });

    test('should be silent when a file is clearly mislocated', () async {
      // A class named `UserModel` (a Model) is in an `entities` directory (for Entities).
      final path = p.join(testProjectPath, 'lib/features/user/domain/entities/user_model.dart');
      writeFile(path, 'class UserModel {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'model', 'pattern': '{{name}}Model'},
          {'on': 'entity', 'pattern': '{{name}}'},
        ],
      );

      expect(
        lints,
        isEmpty,
        reason:
            'This is a location problem, not a naming problem, and should be handled by another '
            'lint.',
      );
    });

    test('should not report violation when no naming rule is defined for the component', () async {
      final path = p.join(testProjectPath, 'lib/features/user/data/models/user_model.dart');
      writeFile(path, 'class UserModel {}');

      // No rule for 'model' is provided.
      final lints = await runLint(filePath: path, namingRules: []);
      expect(lints, isEmpty);
    });
  });
}
