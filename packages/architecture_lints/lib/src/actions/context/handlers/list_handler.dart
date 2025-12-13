// lib/src/actions/context/handlers/list_handler.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/actions/context/handlers/variable_handler.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/parameter_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';

class ListHandler extends VariableHandler {
  const ListHandler(super.engine);

  @override
  dynamic handle(
    VariableConfig config,
    Map<String, dynamic> context,
    VariableResolver resolver,
  ) {
    // A. From Source (Transformer)
    if (config.from != null) {
      var source = engine.evaluate(config.from!, context);

      // FIX: Unwrap ListWrapper to Iterable
      if (source is ListWrapper) {
        // ListWrapper implements List which implements Iterable, so this cast works,
        // but explicit cast helps clarity if needed.
        // Iterate over it directly.
      } else if (source is! Iterable) {
        // If it evaluated to something else (e.g. null), use empty.
        source = [];
      }

      if (source is Iterable) {
        final items = source.map((item) {
          final itemContext = Map<String, dynamic>.from(context);

          // Wrap item based on type
          if (item is FormalParameter) {
            itemContext['item'] = ParameterWrapper(item);
          } else if (item is DartType) {
            itemContext['item'] = TypeWrapper(item);
          } else {
            itemContext['item'] = item; // Could be primitive
          }

          final itemResult = <String, dynamic>{};
          config.mapSchema.forEach((key, subConfig) {
            // Keys in mapSchema start with '.', remove it
            final cleanKey = key.startsWith('.') ? key.substring(1) : key;
            itemResult[cleanKey] = resolver.resolveConfig(subConfig, itemContext);
          });
          return itemResult;
        }).toList();

        return buildListMeta(items);
      }
    }

    // B. Explicit Values
    if (config.values.isNotEmpty) {
      final items = config.values.map((e) => engine.evaluate(e, context)).toList();
      return buildListMeta(items);
    }

    // C. Spread
    if (config.spread.isNotEmpty) {
      final items = <dynamic>[];
      for (final expr in config.spread) {
        final val = engine.evaluate(expr, context);
        if (val is Iterable) {
          items.addAll(val);
        } else {
          items.add(val);
        }
      }
      return buildListMeta(items);
    }

    // Default Empty
    return buildListMeta([]);
  }
}
