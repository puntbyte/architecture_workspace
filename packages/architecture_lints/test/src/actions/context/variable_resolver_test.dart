import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/config/enums/variable_type.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';
import 'package:test/test.dart';

import '../../../helpers/test_resolver.dart';

void main() {
  group('VariableResolver', () {
    late ArchitectureConfig mockConfig;
    late CompilationUnit unit;

    // Helper to get a resolver for a specific method
    VariableResolver getResolverForMethod(String methodName) {
      final clazz = unit.declarations.whereType<ClassDeclaration>().firstWhere(
            (c) => c.name.lexeme == 'AuthPort',
      );
      final method = clazz.members.whereType<MethodDeclaration>().firstWhere(
            (m) => m.name.lexeme == methodName,
      );

      return VariableResolver(
        sourceNode: method,
        config: mockConfig,
        packageName: 'test_project',
      );
    }

    setUp(() async {
      // 1. Setup Source Code
      const code = '''
        import 'dart:async';
        class User {}
        
        class AuthPort {
          // Method 0: Simple Async with Params
          Future<User> login(String username, {required int age});
          
          // Method 1: No Params
          void logout();
        }
      ''';

      final result = await resolveContent(code);
      unit = result.unit;

      // 2. Setup Config with Definitions and Rewrites
      mockConfig = const ArchitectureConfig(
        components: [],
        definitions: {
          'usecase.base': Definition(
            types: ['BaseUseCase'],
            imports: ['package:core/base.dart'],
          ),
          'deep.dep': Definition(
            types: ['Deep'],
            imports: ['package:deep/public.dart'],
            rewrites: ['package:deep/src/internal.dart'],
          ),
        },
      );
    });

    group('Expressions & Strings', () {
      test('should resolve string interpolation', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'methodName': const VariableConfig(
            type: VariableType.string,
            value: r'${source.name}',
          ),
          'className': const VariableConfig(
            type: VariableType.string,
            value: r'${source.parent.name}',
          ),
        };

        final result = resolver.resolveMap(variables);

        expect(result['methodName'], 'login');
        expect(result['className'], 'AuthPort');
      });

      test('should resolve casing properties', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'pascal': const VariableConfig(
              type: VariableType.string,
              value: r'${source.name.pascalCase}'
          ),
          'constant': const VariableConfig(
              type: VariableType.string,
              value: r'${source.name.constantCase}'
          ),
        };

        final result = resolver.resolveMap(variables);

        expect(result['pascal'], 'Login');
        expect(result['constant'], 'LOGIN');
      });
    });

    group('Generics & Types', () {
      test('should resolve Future<User> structure', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          // Future
          'base': const VariableConfig(
            type: VariableType.string,
            value: r'${source.returnType.generics.base.value}',
          ),
          // User
          'inner': const VariableConfig(
            type: VariableType.string,
            value: r'${source.returnType.generics.first.name.value}',
          ),
          'isFuture': const VariableConfig(
            type: VariableType.bool,
            value: 'source.returnType.isFuture',
          ),
        };

        final result = resolver.resolveMap(variables);

        expect(result['base'], 'Future');
        expect(result['inner'], 'User');
        expect(result['isFuture'], true);
      });
    });

    group('Logic & Conditions', () {
      test('should handle conditional logic (select)', () {
        final resolver = getResolverForMethod('login'); // Has params

        final variables = {
          'hasParams': const VariableConfig(
            type: VariableType.string,
            select: [
              VariableSelect(
                condition: 'source.parameters.isNotEmpty',
                // Use quoted literals "'YES'" so expression engine treats them as strings
                result: VariableConfig(type: VariableType.string, value: "'YES'"),
              ),
              VariableSelect(
                result: VariableConfig(type: VariableType.string, value: "'NO'"),
              ),
            ],
          ),
        };

        final result = resolver.resolveMap(variables);
        expect(result['hasParams'], 'YES');
      });

      test('should handle else fallback', () {
        final resolver = getResolverForMethod('logout'); // No params

        final variables = {
          'hasParams': const VariableConfig(
            type: VariableType.string,
            select: [
              VariableSelect(
                condition: 'source.parameters.isNotEmpty',
                result: VariableConfig(type: VariableType.string, value: "'YES'"),
              ),
              VariableSelect(
                result: VariableConfig(type: VariableType.string, value: "'NO'"),
              ),
            ],
          ),
        };

        final result = resolver.resolveMap(variables);
        expect(result['hasParams'], 'NO');
      });
    });

    group('Lists & Maps (Collections)', () {
      test('should transform Lists (ListHandler)', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'params': const VariableConfig(
            type: VariableType.list,
            from: 'source.parameters',
            mapSchema: {
              'name': VariableConfig(type: VariableType.string, value: 'item.name'),
              'isNamed': VariableConfig(type: VariableType.bool, value: 'item.isNamed'),
            },
          ),
        };

        final result = resolver.resolveMap(variables);
        final paramsMap = result['params'] as Map<String, dynamic>;

        expect(paramsMap['length'], 2);

        final items = paramsMap['items'] as List;
        final p1 = items[0] as Map<String, dynamic>;
        final p2 = items[1] as Map<String, dynamic>;

        expect(p1['name'], 'username');
        expect(p1['isNamed'], false);

        expect(p2['name'], 'age');
        expect(p2['isNamed'], true);
      });
    });

    group('Imports (SetHandler)', () {
      test('should aggregate imports and apply rewrites', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'imports': const VariableConfig(
            type: VariableType.set,
            // Trigger ImportExtractor
            transformer: 'imports',
            values: [
              'source.returnType', // Future<User> -> extracts User
              "'package:deep/src/internal.dart'", // Raw string -> Should be rewritten
            ],
          )
        };

        final result = resolver.resolveMap(variables);
        final importsMap = result['imports'] as Map<String, dynamic>;
        final items = importsMap['items'] as List;

        // 1. User import (converted from local path)
        expect(
            items.any((i) => i.toString().contains('package:test_project/test.dart')),
            isTrue,
            reason: 'Expected package:test_project/test.dart in $items'
        );

        // 2. Rewrite check: 'deep/src/internal.dart' -> 'deep/public.dart' (from mockConfig)
        expect(items, contains('package:deep/public.dart'));
        expect(items, isNot(contains('package:deep/src/internal.dart')));
      });
    });

    group('Config Access', () {
      test('should access definitions map via config.definitionFor', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'baseClass': const VariableConfig(
            type: VariableType.string,
            // Access definition via helper method on ConfigWrapper
            // The method returns a Map, so we can access .type
            value: r"${config.definitionFor('usecase.base').type}",
          ),
        };

        final result = resolver.resolveMap(variables);
        expect(result['baseClass'], 'BaseUseCase');
      });
    });
  });
}