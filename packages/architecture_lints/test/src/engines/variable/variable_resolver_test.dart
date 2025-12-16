import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/engines/variable/variable_resolver.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:architecture_lints/src/schema/definitions/variable_definition.dart';
import 'package:architecture_lints/src/schema/descriptors/variable_select.dart';
import 'package:architecture_lints/src/schema/enums/variable_type.dart';
import 'package:test/test.dart';

import '../../../helpers/test_resolver.dart';

void main() {
  group('VariableResolver', () {
    late ArchitectureConfig mockConfig;
    late CompilationUnit unit;

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
          Future<User> login(String username, {required int age}) {}
          void logout();
        }
      ''';

      final result = await resolveContent(code);
      unit = result.unit;

      // 2. Setup Config
      mockConfig = const ArchitectureConfig(
        components: [
          // Added for the chaining test
          ComponentDefinition(
            id: 'domain.usecase',
            patterns: ['{{name}}UseCase'],
          ),
        ],
        definitions: {
          'usecase.base': TypeDefinition(
            types: ['BaseUseCase'],
            imports: ['package:core/base.dart'],
          ),
          'deep.dep': TypeDefinition(
            types: ['Deep'],
            imports: ['package:deep/public.dart'],
            rewrites: ['package:deep/src/internal.dart'],
          ),
        },
      );
    });

    group('Expressions & Strings', () {
      test('should resolve string interpolation ({{...}})', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'methodName': const VariableDefinition(
            type: VariableType.string,
            value: '{{source.name}}',
          ),
          'className': const VariableDefinition(
            type: VariableType.string,
            value: '{{source.parent.name}}',
          ),
        };

        final result = resolver.resolveMap(variables);

        expect(result['methodName'], 'login');
        expect(result['className'], 'AuthPort');
      });

      test('should resolve casing properties', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'pascal': const VariableDefinition(
            type: VariableType.string,
            value: '{{source.name.pascalCase}}',
          ),
          'constant': const VariableDefinition(
            type: VariableType.string,
            value: '{{source.name.constantCase}}',
          ),
        };

        final result = resolver.resolveMap(variables);

        expect(result['pascal'], 'Login');
        expect(result['constant'], 'LOGIN');
      });

      test('should resolve string replace method within interpolation', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'replaced': const VariableDefinition(
            type: VariableType.string,
            value: "{{source.name.replace('log', 'Sign')}}",
          ),
        };

        final result = resolver.resolveMap(variables);
        expect(result['replaced'], 'Signin');
      });
    });

    group('Complex Chaining', () {
      test('should chain variables and perform replacement from config', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          // 1. Fetch raw pattern from config: "{{name}}UseCase"
          'usecasePattern': const VariableDefinition(
            type: VariableType.string,
            value: "{{config.namesFor('domain.usecase').pattern.first}}",
          ),
          // 2. Perform Replacement
          // Note: We construct the string '{{' + 'name}}' to be used as the *argument*
          // to replace(), so ExpressionEngine doesn't misinterpret it as nested interpolation start.
          // Or simply rely on the fact that it is inside a string literal within the expression.
          'usecaseName': const VariableDefinition(
            type: VariableType.string,
            value: "{{usecasePattern.replace('{{name}}', source.name.pascalCase)}}",
          ),
        };

        final result = resolver.resolveMap(variables);

        // Verify intermediate step (Raw value from config)
        expect(result['usecasePattern'], '{{name}}UseCase');

        // Verify final result (Replacement applied)
        expect(result['usecaseName'], 'LoginUseCase');
      });
    });

    group('Generics & Types', () {
      test('should resolve Future<User> structure', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'base': const VariableDefinition(
            type: VariableType.string,
            value: '{{source.returnType.generics.base.value}}',
          ),
          'inner': const VariableDefinition(
            type: VariableType.string,
            value: '{{source.returnType.generics.first.name.value}}',
          ),
          'isFuture': const VariableDefinition(
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
        final resolver = getResolverForMethod('login');

        final variables = {
          'hasParams': const VariableDefinition(
            type: VariableType.string,
            select: [
              VariableSelect(
                condition: 'source.parameters.isNotEmpty',
                result: VariableDefinition(type: VariableType.string, value: "'YES'"),
              ),
              VariableSelect(
                result: VariableDefinition(type: VariableType.string, value: "'NO'"),
              ),
            ],
          ),
        };

        final result = resolver.resolveMap(variables);
        expect(result['hasParams'], 'YES');
      });

      test('should handle else fallback', () {
        final resolver = getResolverForMethod('logout');

        final variables = {
          'hasParams': const VariableDefinition(
            type: VariableType.string,
            select: [
              VariableSelect(
                condition: 'source.parameters.isNotEmpty',
                result: VariableDefinition(type: VariableType.string, value: "'YES'"),
              ),
              VariableSelect(
                result: VariableDefinition(type: VariableType.string, value: "'NO'"),
              ),
            ],
          ),
        };

        final result = resolver.resolveMap(variables);
        expect(result['hasParams'], 'NO');
      });
    });

    group('Lists & Maps', () {
      test('should transform Lists', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'params': const VariableDefinition(
            type: VariableType.list,
            from: 'source.parameters',
            mapSchema: {
              'name': VariableDefinition(type: VariableType.string, value: 'item.name'),
              'isNamed': VariableDefinition(type: VariableType.bool, value: 'item.isNamed'),
            },
          ),
        };

        final result = resolver.resolveMap(variables);
        final paramsMap = result['params'] as Map<String, dynamic>;

        expect(paramsMap['length'], 2);

        final items = paramsMap['items'] as List;
        final p1 = items[0] as Map<String, dynamic>;
        expect(p1['name'], 'username');
        expect(p1['isNamed'], false);
      });
    });

    group('Imports (SetHandler)', () {
      test('should aggregate imports and apply rewrites', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'imports': const VariableDefinition(
            type: VariableType.set,
            transformer: 'imports',
            values: [
              'source.returnType',
              "'package:deep/src/internal.dart'",
            ],
          ),
        };

        final result = resolver.resolveMap(variables);
        final importsMap = result['imports'] as Map<String, dynamic>;
        final items = importsMap['items'] as List;

        expect(
          items.any((i) => i.toString().contains('package:test_project/test.dart')),
          isTrue,
        );

        expect(items, contains('package:deep/public.dart'));
        expect(items, isNot(contains('package:deep/src/internal.dart')));
      });
    });

    group('Config Access', () {
      test('should access definitions map via config.definitionFor', () {
        final resolver = getResolverForMethod('login');

        final variables = {
          'baseClass': const VariableDefinition(
            type: VariableType.string,
            value: "config.definitionFor('usecase.base').type",
          ),
        };

        final result = resolver.resolveMap(variables);
        expect(result['baseClass'], 'BaseUseCase');
      });
    });
  });
}
