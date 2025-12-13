import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/handlers/conditional_handler.dart';
import 'package:architecture_lints/src/actions/context/handlers/list_handler.dart';
import 'package:architecture_lints/src/actions/context/handlers/map_handler.dart';
import 'package:architecture_lints/src/actions/context/handlers/set_handler.dart';
import 'package:architecture_lints/src/actions/context/helpers/import_extractor.dart';
import 'package:architecture_lints/src/config/enums/variable_type.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';

class VariableResolver {
  final ExpressionEngine _engine;
  final ConditionalHandler _conditionalHandler;
  final ListHandler _listHandler;
  final SetHandler _setHandler;
  final MapHandler _mapHandler;

  VariableResolver({
    required AstNode sourceNode,
    required ArchitectureConfig config,
    required String packageName,
  }) : _engine = ExpressionEngine(sourceNode: sourceNode, config: config),
        _conditionalHandler = ConditionalHandler(
          ExpressionEngine(sourceNode: sourceNode, config: config),
        ),
        _listHandler = ListHandler(
          ExpressionEngine(sourceNode: sourceNode, config: config),
        ),
        _setHandler = SetHandler(
          ExpressionEngine(sourceNode: sourceNode, config: config),
          ImportExtractor(packageName),
        ),
        _mapHandler = MapHandler(
          ExpressionEngine(sourceNode: sourceNode, config: config),
        );

  Map<String, dynamic> resolveMap(Map<String, dynamic> variablesConfig) {
    final result = <String, dynamic>{};

    variablesConfig.forEach((key, value) {
      // print('[VariableResolver] Map Key: $key, ValueType: ${value.runtimeType}');

      dynamic resolvedValue;
      if (value is String) {
        resolvedValue = _engine.evaluate(value, result);
      } else if (value is VariableConfig) {
        resolvedValue = resolveConfig(value, result);
      } else if (value is Map<String, dynamic> && !key.startsWith('.')) {
        resolvedValue = resolveMap(value);
      }

      result[key] = resolvedValue;
    });

    if (!result.containsKey('source')) {
      result['source'] = _engine.unwrap(_engine.rootContext['source']);
    }

    return result;
  }

  dynamic resolve(String expression) => _engine.evaluate(expression, {});

  dynamic resolveConfig(VariableConfig config, Map<String, dynamic> context) {
    // print('[VariableResolver] resolveConfig type=${config.type}, select=${config.select.length}, value=${config.value}');

    // 1. Logic Branching
    if (config.select.isNotEmpty) {
      final selectedConfig = _conditionalHandler.handle(config.select, context);
      if (selectedConfig != null) {
        // print('[VariableResolver] Branch matched. Recursing...');
        return resolveConfig(selectedConfig, context);
      }
      print('[VariableResolver] WARNING: No branch matched in select.');
      return null;
    }

    dynamic result;
    switch (config.type) {
      case VariableType.list:
        result = _listHandler.handle(config, context, this);
        break;
      case VariableType.set:
        result = _setHandler.handle(config, context, this);
        break;
      case VariableType.map:
        result = _mapHandler.handle(config, context, this);
        break;
      default: // Primitives
        if (config.value != null) {
          // print('[VariableResolver] Evaluating primitive value: "${config.value}"');
          result = _engine.evaluate(config.value!, context);
          // print('[VariableResolver] Eval result: $result');
        } else {
          // print('[VariableResolver] Primitive has null value');
        }
    }

    if (config.children.isNotEmpty) {
      Map<String, dynamic> resultMap;
      if (result is Map<String, dynamic>) {
        resultMap = result;
      } else {
        resultMap = {};
        if (result != null) resultMap['value'] = result;
      }

      config.children.forEach((childKey, childConfig) {
        resultMap[childKey] = resolveConfig(childConfig, context);
      });

      return _engine.unwrap(resultMap);
    }

    final unwrapped = _engine.unwrap(result);
    // print('[VariableResolver] Final Unwrapped Result: $unwrapped');
    return unwrapped;
  }
}