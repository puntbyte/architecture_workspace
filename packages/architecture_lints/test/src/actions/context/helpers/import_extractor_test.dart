import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/helpers/import_extractor.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/node_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/parameter_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

void main() {
  group('ImportExtractor', () {
    late ImportExtractor extractor;
    const packageName = 'test_project';

    setUp(() {
      extractor = const ImportExtractor(packageName);
    });

    test('should extract simple URIs from Strings', () {
      final imports = <String>{};

      extractor
        ..extract('package:a/a.dart', imports)
        ..extract('dart:async', imports)
        ..extract('dart:core', imports); // Should be ignored

      expect(imports, containsAll(['package:a/a.dart', 'dart:async']));
      expect(imports, isNot(contains('dart:core')));
    });

    test('should extract imports from Definition objects', () {
      final imports = <String>{};
      const def = Definition(
        imports: ['package:b/b.dart', 'package:c/c.dart'],
      );

      extractor.extract(def, imports);

      expect(imports, containsAll(['package:b/b.dart', 'package:c/c.dart']));
    });

    test('should normalize deep imports (fpdart)', () {
      final imports = <String>{};

      extractor.extract('package:fpdart/src/either.dart', imports);

      expect(imports, contains('package:fpdart/fpdart.dart'));
      expect(imports, isNot(contains('package:fpdart/src/either.dart')));
    });

    test('should convert absolute file paths to package URIs', () {
      final imports = <String>{};

      // Simulate an absolute path found on disk
      // e.g. /User/project/lib/features/auth/user.dart
      final absPath = p.join('root', 'project', 'lib', 'features', 'auth', 'user.dart');

      extractor.extract(absPath, imports);

      // Should convert using the packageName passed in constructor
      expect(imports, contains('package:test_project/features/auth/user.dart'));
    });

    group('AST Integration', () {
      late CompilationUnit unit;

      setUp(() async {
        const code = '''
          import 'dart:async';
          class User {}
          class Box<T> {}
          
          class TestClass {
            void method(User user, Box<User> box) {}
          }
        ''';
        final result = await resolveContent(code);
        unit = result.unit;
      });

      test('should extract import from TypeWrapper', () {
        final imports = <String>{};

        final clazz = unit.declarations.whereType<ClassDeclaration>().firstWhere(
          (c) => c.name.lexeme == 'User',
        );
        final element = clazz.declaredFragment!.element;
        final typeWrapper = TypeWrapper(element.thisType);

        extractor.extract(typeWrapper, imports);

        // The test file simulates 'package:test_project/lib/test.dart'
        // Resolver usually treats 'lib/test.dart' as 'package:test_project/test.dart'
        expect(imports.first, contains('package:test_project/test.dart'));
      });

      test('should extract imports recursively from Generics (Box<User>)', () {
        final imports = <String>{};

        final clazz = unit.declarations.whereType<ClassDeclaration>().firstWhere(
          (c) => c.name.lexeme == 'TestClass',
        );
        final method = clazz.members.whereType<MethodDeclaration>().first;
        final paramBox = method.parameters!.parameters[1]; // Box<User> box

        final typeWrapper = TypeWrapper(paramBox.declaredFragment!.element.type);

        extractor.extract(typeWrapper, imports);

        // Should extract import for the file defining Box AND User
        // Since they are in the same file, we just check it exists
        expect(imports, isNotEmpty);
        expect(imports.first, contains('package:test_project/test.dart'));
      });

      test('should extract import from NodeWrapper (File path)', () {
        final imports = <String>{};
        final clazz = unit.declarations.first; // Class User
        final nodeWrapper = NodeWrapper(clazz);

        extractor.extract(nodeWrapper, imports);

        // NodeWrapper.filePath returns absolute path.
        // Extractor should convert it to package: URI
        expect(imports, contains(matches('package:test_project/.*test.dart')));
      });

      test('should extract imports from ParameterWrapper', () {
        final imports = <String>{};
        final clazz = unit.declarations.whereType<ClassDeclaration>().firstWhere(
          (c) => c.name.lexeme == 'TestClass',
        );
        final method = clazz.members.whereType<MethodDeclaration>().first;
        final param = ParameterWrapper(method.parameters!.parameters[0]); // User user

        extractor.extract(param, imports);

        expect(imports, contains(matches('package:test_project/.*test.dart')));
      });
    });

    test('should handle Lists and ListWrappers', () {
      final imports = <String>{};

      final list = ['package:a/a.dart', 'package:b/b.dart'];
      const wrapper = ListWrapper(['package:c/c.dart']);

      extractor
        ..extract(list, imports)
        ..extract(wrapper, imports);

      expect(imports, containsAll(['package:a/a.dart', 'package:b/b.dart', 'package:c/c.dart']));
    });
  });
}
