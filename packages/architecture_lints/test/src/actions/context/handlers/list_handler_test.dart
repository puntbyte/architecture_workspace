import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/engines/expression/expression_resolver.dart';
import 'package:architecture_lints/src/engines/variable/handlers/list_handler.dart';
import 'package:architecture_lints/src/engines/variable/variable_resolver.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/schema/enums/variable_type.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/variable_definition.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

void main() {
  group('ListHandler', () {
    late ExpressionResolver engine;
    late ListHandler handler;
    late VariableResolver resolver; // Needed for recursive mapping

    setUp(() async {
      const code = '''
        class A { 
          void f(String a, int b) {} 
        }
      ''';
      final unit = await resolveContent(code);
      final clazz = unit.unit.declarations.whereType<ClassDeclaration>().first;
      final method = clazz.members.whereType<MethodDeclaration>().first;

      final config = ArchitectureConfig.empty();
      engine = ExpressionResolver(node: method, config: config);
      handler = ListHandler(engine);

      // We need a real resolver because ListHandler calls resolver.resolveConfig recursively
      resolver = VariableResolver(
        sourceNode: method,
        config: config,
        packageName: 'test',
      );
    });

    test('should transform source list (AST Nodes) into Maps', () {
      const config = VariableDefinition(
        type: VariableType.list,
        from: 'source.parameters', // ListWrapper<ParameterWrapper>
        mapSchema: {
          'name': VariableDefinition(type: VariableType.string, value: 'item.name'),
          'isNamed': VariableDefinition(type: VariableType.bool, value: 'item.isNamed'),
        },
      );

      final result = handler.handle(config, {}, resolver) as List;

      expect(result.length, 2);

      final first = result[0] as Map<String, dynamic>;
      expect(first['name'], 'a');
      expect(first['isNamed'], false);

      final second = result[1] as Map<String, dynamic>;
      expect(second['name'], 'b');
    });

    test('should handle explicit values', () {
      const config = VariableDefinition(
        type: VariableType.list,
        values: ["'A'", "'B'"],
      );

      final result = handler.handle(config, {}, resolver) as List;
      expect(result, ['A', 'B']);
    });

    test('should handle spread', () {
      const config = VariableDefinition(
        type: VariableType.list,
        spread: ['list1', 'list2'],
      );

      final context = {
        'list1': const ListWrapper(['a', 'b']),
        'list2': ['c'],
      };

      final result = handler.handle(config, context, resolver) as List;
      expect(result, ['a', 'b', 'c']);
    });
  });
}
