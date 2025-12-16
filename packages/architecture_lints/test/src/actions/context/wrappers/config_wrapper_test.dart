import 'package:architecture_lints/src/engines/expression/expression_engine.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/config_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:expressions/expressions.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigWrapper', () {
    late ExpressionEvaluator evaluator;
    late ConfigWrapper configWrapper;

    setUp(() {
      evaluator = ExpressionEngine.evaluator();

      const config = ArchitectureConfig(
        components: [
          ComponentDefinition(
            id: 'domain.usecase',
            patterns: [r'${name}UseCase'],
          ),
        ],
        definitions: {
          'usecase.base': TypeDefinition(types: ['BaseUseCase']),
        },
      );
      configWrapper = const ConfigWrapper(config);
    });

    test('should access definitionFor', () {
      final defMap = evaluator.eval(
        Expression.parse("c.definitionFor('usecase.base')"),
        {'c': configWrapper},
      );

      expect(defMap, isA<Map>());
      expect(defMap['types'], ['BaseUseCase']);
    });

    test('should access namesFor', () {
      final names = evaluator.eval(
        Expression.parse("c.namesFor('domain.usecase')"),
        {'c': configWrapper},
      );

      expect(names, isA<Map>());
      final patterns = names['pattern'] as ListWrapper;
      expect(patterns.first.toString(), r'${name}UseCase');
    });
  });
}
