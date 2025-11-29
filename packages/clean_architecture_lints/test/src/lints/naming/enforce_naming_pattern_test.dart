import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/naming/enforce_naming_pattern.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';
import '../../../utils/debug_utils.dart';

void main() {
  group('EnforceNamingPattern Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('naming_pattern_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: example');
      addFile('.dart_tool/package_config.json', '{"configVersion": 2, "packages": []}');

      // Setup base classes for inheritance checks
      addFile('lib/core/port/port.dart', 'abstract interface class Port {}');
      addFile('lib/core/entity/entity.dart', 'abstract class Entity {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> namingRules,
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      // Optional: Uncomment to see analyzer state if a test fails
      DebugUtils.printAnalysisState(resolvedUnit, makeConfig());

      final config = makeConfig(namingRules: namingRules, inheritances: inheritances);
      final lint = EnforceNamingPattern(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    // --- SCENARIO 1: Basic Pattern Matching ---

    test('should report violation when class name does not match the required pattern', () async {
      const path = 'lib/features/user/data/models/user.dart';
      addFile(path, 'class User {}'); // Should be UserModel

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'model', 'pattern': '{{name}}Model'},
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('does not match the required pattern "{{name}}Model"'));
    });

    test('should not report violation when class name matches the required pattern', () async {
      const path = 'lib/features/user/data/models/user_model.dart';
      addFile(path, 'class UserModel {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'model', 'pattern': '{{name}}Model'},
        ],
      );

      expect(lints, isEmpty);
    });

    // --- SCENARIO 2: Yield Strategy (Mislocation) ---

    test('should yield to location lint when name matches another component pattern (Mislocation)', () async {
      // Scenario: 'UserModel' is inside the 'entities' directory.
      // 'UserModel' matches the Model pattern perfectly.
      // Since it does NOT match the Entity pattern ({{name}}), we assume it's misplaced.
      // The Naming lint should yield (return empty) so the Location lint can handle it.
      const path = 'lib/features/user/domain/entities/user_model.dart';
      addFile(path, 'class UserModel {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'model', 'pattern': '{{name}}Model'},
          {'on': 'entity', 'pattern': '{{name}}'},
        ],
      );

      expect(lints, isEmpty, reason: 'Should yield to EnforceFileAndFolderLocation');
    });

    // --- SCENARIO 3: Intent Check (Inheritance Override) ---

    test('should NOT yield (and report violation) when inheritance signals intent', () async {
      // Scenario: 'AuthContract' is in 'ports' directory.
      // It matches the Entity pattern {{name}} (Ambiguous/Mislocation risk).
      // BUT it implements 'Port'. This signals the user explicitly wants this to be a Port.
      // Therefore, we should NOT yield, and instead enforce the Port naming rule ({{name}}Port).
      const path = 'lib/features/auth/domain/ports/auth_contract.dart';
      addFile(path, '''
        import '../../../../core/port/port.dart';
        abstract interface class AuthContract implements Port {}
      ''');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'port', 'pattern': '{{name}}Port'},
          {'on': 'entity', 'pattern': '{{name}}'},
        ],
        inheritances: [
          {'on': 'port', 'required': {'name': 'Port', 'import': 'package:example/core/port/port.dart'}}
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('does not match the required pattern "{{name}}Port"'));
    });

    test('should NOT yield when inheritance signals intent, even if name matches nothing known', () async {
      // Name 'AuthThing' matches neither Port pattern nor Entity pattern.
      // But it implements Port. We should enforce Port naming.
      const path = 'lib/features/auth/domain/ports/auth_thing.dart';
      addFile(path, '''
        import '../../../../core/port/port.dart';
        abstract interface class AuthThing implements Port {}
      ''');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'port', 'pattern': '{{name}}Port'},
        ],
        inheritances: [
          {'on': 'port', 'required': {'name': 'Port', 'import': 'package:example/core/port/port.dart'}}
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('does not match the required pattern "{{name}}Port"'));
    });

    // --- SCENARIO 4: Edge Cases ---

    test('should not report violation when no naming rule is defined', () async {
      const path = 'lib/features/user/data/models/user.dart';
      addFile(path, 'class User {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [], // Empty rules
      );

      expect(lints, isEmpty);
    });
  });
}
