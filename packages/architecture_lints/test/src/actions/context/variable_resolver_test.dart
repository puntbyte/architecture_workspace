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

    // Helper to get a resolver for a specific method in the test file
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
      // 1. Setup Source with various Types
      const code = '''
        import 'dart:async';
        class User {}
        
        class AuthPort {
          // Method 0: Simple Async
          Future<User> login(String username, {required int age});
          
          // Method 1: Complex Generics
          Map<String, int> getMetaData();
          
          // Method 2: List Generics
          List<String> getTags();
          
          // Method 3: No Params
          void logout();
        }
      ''';

      final result = await resolveContent(code);
      unit = result.unit;

      // 2. Setup Config
      mockConfig = const ArchitectureConfig(
        components: [],
        definitions: {
          'usecase.base': Definition(
            types: ['BaseUseCase'],
            imports: ['package:core/base.dart'],
          ),
        },
      );
    });

    group('Generics & Type Analysis', () {
      test('should resolve Future<T> generics', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'base': const VariableConfig(
              type: VariableType.string,
              value: r'${source.returnType.generics.base}' // Future
          ),
          'inner': const VariableConfig(
              type: VariableType.string,
              value: r'${source.returnType.generics.first.name}' // User
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

      test('should resolve Map<K, V> generics (first/last)', () {
        final resolver = getResolverForMethod('getMetaData');

        final variables = {
          'base': const VariableConfig(
              type: VariableType.string,
              value: r'${source.returnType.generics.base}'
          ),
          'keyType': const VariableConfig(
              type: VariableType.string,
              value: r'${source.returnType.generics.first.name}'
          ),
          'valueType': const VariableConfig(
              type: VariableType.string,
              value: r'${source.returnType.generics.last.name}'
          ),
          'argCount': const VariableConfig(
              type: VariableType.number,
              value: 'source.returnType.generics.length'
          ),
        };

        final result = resolver.resolveMap(variables);
        expect(result['base'], 'Map');
        expect(result['keyType'], 'String');
        expect(result['valueType'], 'int');
        expect(result['argCount'], 2);
      });

      test('should resolve nested args via list index (at)', () {
        final resolver = getResolverForMethod('getMetaData');

        final variables = {
          // Access args list directly: args.at(0)
          'firstArg': const VariableConfig(
            type: VariableType.string,
            value: r'${source.returnType.generics.args.at(0).name}',
          ),
        };

        final result = resolver.resolveMap(variables);
        expect(result['firstArg'], 'String');
      });
    });

    group('Expressions & Strings', () {
      test('should resolve simple string interpolation', () {
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

    group('Logic & Conditions', () {
      test('should handle conditional logic (select)', () {
        final resolver = getResolverForMethod('login'); // Has params

        final variables = {
          'hasParams': const VariableConfig(
            type: VariableType.string,
            select: [
              VariableSelect(
                condition: 'source.parameters.isNotEmpty',
                // Note: Quoted literals for strings inside expressions
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

    group('Collections (Lists/Sets/Imports)', () {
      test('should transform Lists (ListHandler)', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'params': const VariableConfig(
            type: VariableType.list,
            from: 'source.parameters',
            mapSchema: {
              'paramName': VariableConfig(type: VariableType.string, value: 'item.name'),
              'isNamed': VariableConfig(type: VariableType.bool, value: 'item.isNamed'),
            },
          ),
        };

        final result = resolver.resolveMap(variables);
        final paramsList = result['params'] as Map<String, dynamic>;

        expect(paramsList['length'], 2);
        expect(paramsList['hasMany'], true);

        final items = paramsList['items'] as List;
        final first = items[0] as Map<String, dynamic>; // username
        final second = items[1] as Map<String, dynamic>; // age

        expect(first['paramName'], 'username');
        expect(first['isNamed'], false);

        expect(second['paramName'], 'age');
        expect(second['isNamed'], true);
      });

      test('should aggregate Imports (SetHandler)', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'imports': const VariableConfig(
            type: VariableType.set,
            values: [
              'source.returnType', // Future<User>
              "'package:manual/manual.dart'",
            ],
          )
        };

        final result = resolver.resolveMap(variables);
        final imports = result['imports'] as Map<String, dynamic>;
        final items = imports['items'] as List;

        expect(items, contains('package:manual/manual.dart'));
        // User is defined in test file -> converted to package URI
        expect(items.any((i) => i.toString().contains('package:test_project/test.dart')), isTrue);
      });
    });

    group('Config Access', () {
      test('should access Definitions from config via map lookup', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'baseClass': const VariableConfig(
            type: VariableType.string,
            // Access map using string key syntax
            value: r"${definitions['usecase.base'].type}",
          ),
        };

        final result = resolver.resolveMap(variables);
        expect(result['baseClass'], 'BaseUseCase');
      });
    });
  });
}