// test/src/utils/ast_utils_test.dart

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_lints/src/utils/ast_utils.dart';
import 'package:test/test.dart';

void main() {
  group('AstUtils', () {
    group('getParameterTypeNode', () {
      // A more robust helper that finds the first constructor and its first parameter.
      FormalParameter getFirstParameter(String source) {
        final parseResult = parseString(content: source, throwIfDiagnostics: false);
        final classNode = parseResult.unit.declarations.first as ClassDeclaration;
        // THE FIX: Specifically find the constructor, don't assume it's the first member.
        final constructor = classNode.members.whereType<ConstructorDeclaration>().first;
        return constructor.parameters.parameters.first;
      }

      test('should return the type for a simple required positional parameter', () {
        final parameter = getFirstParameter('class C { C(String name); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode?.toSource(), 'String');
      });

      test('should return the type for a simple required named parameter', () {
        final parameter = getFirstParameter('class C { C({required String name}); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode?.toSource(), 'String');
      });

      test('should return the type for an optional positional parameter', () {
        final parameter = getFirstParameter('class C { C([String? name]); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode?.toSource(), 'String?');
      });

      test('should return null for a field formal parameter without an explicit type', () {
        final parameter = getFirstParameter('class C { final String name; C(this.name); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        // This is correct behavior, as `this.name` has no explicit type annotation on the parameter itself.
        expect(typeNode, isNull);
      });

      test('should return the type for a field formal parameter with an explicit type', () {
        final parameter = getFirstParameter('class C { final String name; C(String this.name); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode?.toSource(), 'String');
      });

      test('should return the type for a function-typed parameter', () {
        // THE FIX: The expected result for `void callback()` is the `void` TypeAnnotation.
        final parameter = getFirstParameter('class C { C(void callback()); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode, isNotNull);
        expect(typeNode?.toSource(), 'void');
      });

      test('should return null for a super formal parameter without an explicit type', () {
        const source = '''
          class P { P({required String name}); }
          class C extends P { C({required super.name}); }
        ''';
        final parseResult = parseString(content: source, throwIfDiagnostics: false);
        final classC = parseResult.unit.declarations[1] as ClassDeclaration;
        final constructor = classC.members.first as ConstructorDeclaration;
        final parameter = constructor.parameters.parameters.first;
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode, isNull);
      });
    });
  });
}
