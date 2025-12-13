import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/actions/context/architectural_member_accessors.dart';
import 'package:architecture_lints/src/actions/context/wrappers/config_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/generic_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/method_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:expressions/expressions.dart';
import 'package:test/test.dart';

import '../../../helpers/test_resolver.dart';

void main() {
  group('ArchitectureMemberAccessors', () {
    late ExpressionEvaluator evaluator;

    setUp(() {
      evaluator = ExpressionEvaluator(memberAccessors: ArchitectureMemberAccessors.getAll());
    });

    dynamic eval(dynamic object, String expressionStr) {
      final expression = Expression.parse(expressionStr);
      final context = {'obj': object};
      return evaluator.eval(expression, context);
    }

    group('ListWrapper', () {
      test('should access properties', () {
        const list = ListWrapper<String>(['a', 'b']);
        expect(eval(list, 'obj.hasMany'), true);
        expect(eval(list, 'obj.length'), 2);
        expect(eval(list, 'obj.first'), 'a');
        expect(eval(list, 'obj.at(1)'), 'b');
        expect(eval(list, 'obj.at(99)'), isNull);
      });
    });

    group('StringWrapper', () {
      test('should access casing properties (returning String)', () {
        const wrapper = StringWrapper('user_data');
        expect(eval(wrapper, 'obj.pascalCase'), 'UserData');
        expect(eval(wrapper, 'obj.snakeCase'), 'user_data');
      });

      test('should access boolean properties', () {
        const wrapper = StringWrapper('hello');
        expect(eval(wrapper, 'obj.isNotEmpty'), true);
        expect(eval(wrapper, 'obj.length'), 5);
      });
    });

    group('TypeWrapper & GenericWrapper', () {
      late TypeWrapper futureWrapper;

      setUp(() {
        // Mock Future<int>
        final generic = GenericWrapper(
          const StringWrapper('Future'),
          ListWrapper([TypeWrapper(null, rawString: 'int')]),
        );

        // We can't easily mock TypeWrapper with DartType in unit tests without resolver,
        // so we test the GenericWrapper directly or mock TypeWrapper properties via subclass if needed.
        // For this test, we test GenericWrapper directly.
      });

      test('should access GenericWrapper properties', () {
        final generic = GenericWrapper(
          const StringWrapper('Map'),
          ListWrapper([
            TypeWrapper(null, rawString: 'String'),
            TypeWrapper(null, rawString: 'int'),
          ]),
        );

        expect(eval(generic, 'obj.base.value'), 'Map');
        expect(eval(generic, 'obj.length'), 2);

        // Check first arg (TypeWrapper) -> name (StringWrapper) -> value (String)
        expect(eval(generic, 'obj.first.name.value'), 'String');
        expect(eval(generic, 'obj.last.name.value'), 'int');
      });
    });

    group('ConfigWrapper', () {
      late ConfigWrapper configWrapper;

      setUp(() {
        const config = ArchitectureConfig(
          components: [
            ComponentConfig(
              id: 'domain.port',
              patterns: [r'${name}Port'], // New syntax
              antipatterns: [r'${name}Interface'],
            ),
          ],
          definitions: {
            'usecase.base': Definition(types: ['BaseUseCase']),
          },
        );
        configWrapper = const ConfigWrapper(config);
      });

      test('should access definitions map', () {
        // obj.definitions['key'].types
        // Note: accessors return List<String>, not ListWrapper for internal lists of Definition
        final result = eval(configWrapper, "obj.definitions['usecase.base'].types");
        expect(result, ['BaseUseCase']);
      });

      test('should access definitionFor()', () {
        final result = eval(configWrapper, "obj.definitionFor('usecase.base').types");
        expect(result, ['BaseUseCase']);
      });

      test('should access namesFor()', () {
        // config.namesFor('id').pattern
        // namesFor returns Map<String, ListWrapper>
        final patterns = eval(configWrapper, "obj.namesFor('domain.port')['pattern']");

        expect(patterns, isA<ListWrapper>());
        expect(patterns.first.value, r'${name}Port');
      });

      test('should access annotationsFor()', () {
        // annotationsFor returns Map
        final result = eval(configWrapper, "obj.annotationsFor('domain.port')");
        expect(result, isA<Map>());
        expect(result['required'], isA<List>());
      });
    });

    group('NodeWrappers', () {
      Future<MethodWrapper> getMethod(String code) async {
        final unit = await resolveContent(code);
        final clazz = unit.unit.declarations.whereType<ClassDeclaration>().first;
        final method = clazz.members.whereType<MethodDeclaration>().first;
        return MethodWrapper(method);
      }

      test('should access Method/Parameter properties', () async {
        const code = 'class A { void call(int x) {} }';
        final method = await getMethod(code);

        expect(eval(method, 'obj.name.value'), 'call');
        expect(eval(method, 'obj.returnType.name.value'), 'void');
        expect(eval(method, 'obj.parameters.length'), 1);
        expect(eval(method, 'obj.parameters.first.name.value'), 'x');
      });
    });
  });
}
