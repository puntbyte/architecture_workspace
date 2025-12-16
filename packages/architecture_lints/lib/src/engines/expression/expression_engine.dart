import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/config_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/generic_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/method_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/node_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/parameter_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/type_wrapper.dart';
import 'package:expressions/expressions.dart';

class ExpressionEngine {
  final ExpressionEvaluator _evaluator;
  final Map<String, dynamic> rootContext;
  final RegExp _interpolationRegex = RegExp(r'\{\{([^}]+)\}\}');

  ExpressionEngine({
    required AstNode node,
    required ArchitectureConfig config,
  }) : _evaluator = evaluator(),
       rootContext = _rootContext(node, config);

  static ExpressionEvaluator evaluator() => ExpressionEvaluator(
    memberAccessors: [
      // Wrappers
      MethodWrapper.accessor,
      ParameterWrapper.accessor,
      NodeWrapper.accessor,
      TypeWrapper.accessor,
      StringWrapper.accessor,
      GenericWrapper.accessor,

      // Collections
      ListWrapper.accessor,

      // Configuration Objects
      ConfigWrapper.accessor,

      // Default Map support
      MemberAccessor.mapAccessor,
    ],
  );

  static Map<String, dynamic> _rootContext(AstNode sourceNode, ArchitectureConfig config) => {
    'source': NodeWrapper.create(sourceNode, config.definitions),
    'config': ConfigWrapper(config),
    'definitions': config.definitions,
  };

  dynamic evaluate(String input, Map<String, dynamic> context) {
    // 1. Interpolation: "prefix_{{expr}}_suffix"
    if (input.contains('{{')) {
      return input.replaceAllMapped(_interpolationRegex, (match) {
        final expr = match.group(1);
        if (expr == null) return '';

        // Evaluate the inner expression
        final result = _evalRaw(expr.trim(), context);

        // Unwrap to string for the replacement
        return unwrap(result).toString();
      });
    }

    // 2. Pure Expression or Literal
    try {
      return _evalRaw(input, context);
    } catch (e) {
      // 3. Fallback: Literal String
      return input;
    }
  }

  dynamic _evalRaw(String expr, Map<String, dynamic> context) {
    final combinedContext = {...rootContext, ...context};
    try {
      final expression = Expression.parse(expr);
      return _evaluator.eval(expression, combinedContext);
    } catch (e) {
      // Rethrow to let evaluate() handle fallback or caller handle error
      rethrow;
    }
  }

  dynamic unwrap(dynamic value) {
    if (value == null) return null;

    if (value is Definition) return value.toMap();

    if (value is StringWrapper) return value.value;
    if (value is String || value is bool || value is num) return value;
    if (value is TypeWrapper) return unwrap(value.toMap());
    if (value is NodeWrapper) return unwrap(value.toMap());

    if (value is Iterable && value is! Map) return value.map(unwrap).toList();

    if (value is Map) return value.map((key, value) => MapEntry(key.toString(), unwrap(value)));

    return value.toString();
  }
}
