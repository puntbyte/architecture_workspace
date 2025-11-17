// test/src/utils/semantic_utils_test.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/utils/semantic_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

// Helper to resolve a ClassElement from the virtual project.
Future<ClassElement> resolveClassElement(
  AnalysisContextCollection contextCollection,
  String path,
  String className,
) async {
  final context = contextCollection.contextFor(path);
  final unitResult = await context.currentSession.getResolvedUnit(path) as ResolvedUnitResult;
  return unitResult.unit.declarations
      .whereType<ClassDeclaration>()
      .firstWhere((c) => c.name.lexeme == className)
      .declaredFragment!
      .element;
}

void main() {
  group('SemanticUtils', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    // A helper to write a file to the virtual file system.
    void writeFile(String path, String content) {
      final file = resourceProvider.getFile(path);
      file.parent.create();
      file.writeAsStringSync(content);
    }

    setUpAll(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('semantic_utils_test_');
      projectPath = p.join(tempDir.path, 'project');
      final packagesPath = p.join(tempDir.path, 'packages');
      final projectLib = p.join(projectPath, 'lib');

      // Create package_config.json
      writeFile(
        p.join(projectPath, '.dart_tool', 'package_config.json'),
        '''
        {
          "configVersion": 2,
          "packages": [
            { "name": "test_project", "rootUri": "../", "packageUri": "lib/" },
            { "name": "flutter", "rootUri": "${p.toUri(p.join(packagesPath, 'flutter'))}", "packageUri": "lib/" }
          ]
        }
        ''',
      );

      // Create virtual source files with custom paths to match non-default test configs.
      writeFile(
        p.join(projectLib, 'app_features', 'auth', 'domain', 'api', 'auth_api.dart'),
        'abstract interface class AuthApi { void getUser(); String get userId; }',
      );
      writeFile(
        p.join(projectLib, 'app_features', 'auth', 'domain', 'dtos', 'user_dto.dart'),
        'class UserDto {}',
      );
      writeFile(
        p.join(
          projectLib,
          'app_features',
          'auth',
          'data',
          'transfer_objects',
          'user_transfer_object.dart',
        ),
        'class UserTransferObject {}',
      );

      writeFile(p.join(packagesPath, 'flutter', 'lib', 'material.dart'), 'class Color {}');

      contextCollection = AnalysisContextCollection(
        includedPaths: [projectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDownAll(() {
      tempDir.deleteSync(recursive: true);
    });

    group('isArchitecturalOverride', () {
      // THE FIX: Use non-default names to make the test more robust and lint-free.
      final config = makeConfig(featuresModule: 'app_features', contractDir: 'api');
      final layerResolver = LayerResolver(config);

      test('should return true when a method overrides a member from a contract', () async {
        final path = p.join(projectPath, 'lib', 'impl.dart');
        writeFile(path, '''
          import 'package:test_project/app_features/auth/domain/api/auth_api.dart';
          class RepoImpl implements AuthApi { @override void getUser() {} @override String get userId => ""; }
        ''');
        final implClass = await resolveClassElement(contextCollection, path, 'RepoImpl');
        final method = implClass.methods.firstWhere((m) => m.name == 'getUser');

        expect(SemanticUtils.isArchitecturalOverride(method, layerResolver), isTrue);
      });

      test('should return true when a getter overrides a member from a contract', () async {
        final path = p.join(projectPath, 'lib', 'impl.dart');
        final implClass = await resolveClassElement(contextCollection, path, 'RepoImpl');
        final getter = implClass.getGetter('userId');

        expect(getter, isNotNull);
        expect(SemanticUtils.isArchitecturalOverride(getter!, layerResolver), isTrue);
      });

      test('should return false for a method that is not an override', () async {
        final path = p.join(projectPath, 'lib', 'impl2.dart');
        writeFile(path, 'class RepoImpl { void myHelper() {} }');
        final implClass = await resolveClassElement(contextCollection, path, 'RepoImpl');
        final method = implClass.methods.first;

        expect(SemanticUtils.isArchitecturalOverride(method, layerResolver), isFalse);
      });
    });

    group('isComponent', () {
      // THE FIX: Use non-default names.
      final config = makeConfig(
        featuresModule: 'app_features',
        entityDir: 'dtos',
        modelDir: 'transfer_objects',
      );
      final layerResolver = LayerResolver(config);

      test('should return true when a direct type is the specified component', () async {
        final path = p.join(projectPath, 'lib', 'a.dart');
        writeFile(path, '''
          import 'package:test_project/app_features/auth/domain/dtos/user_dto.dart';
          class A { UserDto? user; }
        ''');
        final classA = await resolveClassElement(contextCollection, path, 'A');
        final fieldType = classA.fields.first.type;

        expect(SemanticUtils.isComponent(fieldType, layerResolver, ArchComponent.entity), isTrue);
      });

      test('should return true when a type inside a generic is the specified component', () async {
        final path = p.join(projectPath, 'lib', 'b.dart');
        writeFile(path, '''
          import 'package:test_project/app_features/auth/data/transfer_objects/user_transfer_object.dart';
          class B { List<UserTransferObject>? models; }
        ''');
        final classB = await resolveClassElement(contextCollection, path, 'B');
        final fieldType = classB.fields.first.type;

        expect(SemanticUtils.isComponent(fieldType, layerResolver, ArchComponent.model), isTrue);
      });
    });

    group('isFlutterType', () {
      test('should return true for a type from a Flutter package', () async {
        final path = p.join(projectPath, 'lib', 'c.dart');
        writeFile(path, '''
          import 'package:flutter/material.dart';
          class C { Color? color; }
        ''');
        final classC = await resolveClassElement(contextCollection, path, 'C');
        final fieldType = classC.fields.first.type;

        expect(SemanticUtils.isFlutterType(fieldType), isTrue);
      });
    });
  });
}
