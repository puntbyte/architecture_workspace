import 'dart:io';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/fixes/create_to_entity_method_fix.dart';
import 'package:clean_architecture_lints/src/lints/purity/require_to_entity_method.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/analyzer_test_utils.dart';
import '../../helpers/test_data.dart';

String applySourceChanges(String sourceText, List<SourceChange> changes) {
  String result = sourceText;
  for (final change in changes) {
    for (final edit in change.edits) {
      result = SourceEdit.applySequence(result, edit.edits);
    }
  }
  return result;
}

void main() {
  group('CreateToEntityMethodFix', () {
    late Directory tempDir;
    late String testProjectPath;
    late AnalyzerTestUtils analyzer;
    late LayerResolver debugLayerResolver;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('create_to_entity_fix_test_');
      testProjectPath = p.join(tempDir.path, 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      analyzer = AnalyzerTestUtils(testProjectPath);
      debugLayerResolver = LayerResolver(makeConfig());

      analyzer.writeFile('pubspec.yaml', 'name: test_project');
      analyzer.writeFile('.dart_tool/package_config.json',
          '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}');

      final entityPath = 'lib/features/user/domain/entities/user.dart';
      analyzer.writeFile(entityPath, '''
        class User {
          final String id;
          final String name;
          const User({required this.id, required this.name});
        }
      ''');

      // Debug: Verify component resolution
      final resolvedComponent = debugLayerResolver.getComponent(p.join(testProjectPath, entityPath));
      print('[DEBUG] Component for entity file ($entityPath): $resolvedComponent');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should create a new toEntity method when one is missing', () async {
      final modelPath = 'lib/features/user/data/models/user_model.dart';
      analyzer.writeFile(modelPath, '''
        import 'package:test_project/features/user/domain/entities/user.dart';
        
        class UserModel extends User {
          const UserModel({required super.id, required super.name});
        }
      ''');

      // Debug: Verify component resolution
      final resolvedComponent = debugLayerResolver.getComponent(p.join(testProjectPath, modelPath));
      print('[DEBUG] Component for model file ($modelPath): $resolvedComponent');

      final config = makeConfig();
      final lints = await analyzer.getLints(
        filePath: modelPath,
        lint: RequireToEntityMethod(config: config, layerResolver: analyzer.layerResolver),
      );

      print('[DEBUG] Lints found: ${lints.length}');
      expect(lints, hasLength(1), reason: 'Lint should detect missing toEntity method');

      final fix = CreateToEntityMethodFix(config: config);
      final changes = await analyzer.getFixes(lints.first, fix);

      expect(changes, hasLength(1), reason: 'Fix should generate one change');

      final result = applySourceChanges(analyzer.readFile(modelPath), changes);

      print('[DEBUG] Final generated code:\n$result');

      expect(result, contains('@override'));
      expect(result, contains('User toEntity()'));
      expect(result, contains('return User(id: id, name: name);'));
    });

    test('should correct an existing toEntity method with the wrong signature', () async {
      final modelPath = 'lib/features/user/data/models/user_model.dart';
      analyzer.writeFile(modelPath, '''
        import 'package:test_project/features/user/domain/entities/user.dart';
        
        class UserModel extends User {
          const UserModel({required super.id, required super.name});
          
          void toEntity() {} // Wrong signature
        }
      ''');

      final config = makeConfig();
      final lints = await analyzer.getLints(
        filePath: modelPath,
        lint: RequireToEntityMethod(config: config, layerResolver: analyzer.layerResolver),
      );

      print('[DEBUG] Lints found (correction test): ${lints.length}');
      expect(lints, hasLength(1), reason: 'Lint should detect incorrect toEntity method');

      final fix = CreateToEntityMethodFix(config: config);
      final changes = await analyzer.getFixes(lints.first, fix);

      expect(changes, hasLength(1), reason: 'Fix should generate one change');

      final result = applySourceChanges(analyzer.readFile(modelPath), changes);

      expect(result, contains('@override\n  User toEntity()'));
      expect(result, isNot(contains('void toEntity()')));
    });
  });
}
