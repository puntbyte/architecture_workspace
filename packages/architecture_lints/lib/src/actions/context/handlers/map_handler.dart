// lib/src/actions/context/handlers/map_handler.dart

import 'package:architecture_lints/src/actions/context/handlers/variable_handler.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';

class MapHandler extends VariableHandler {
  const MapHandler(super.engine);

  @override
  dynamic handle(
    VariableConfig config,
    Map<String, dynamic> context,
    VariableResolver resolver,
  ) {
    final result = <String, dynamic>{};

    // 1. Explicit Value (if provided, though rare for 'map' type)
    if (config.value != null) {
      final val = engine.evaluate(config.value!, context);
      if (val is Map) result.addAll(val.cast<String, dynamic>());
    }

    // 2. Spread (Merge other maps)
    if (config.spread.isNotEmpty) {
      for (final expr in config.spread) {
        final val = engine.evaluate(expr, context);
        if (val is Map) result.addAll(val.cast<String, dynamic>());
      }
    }

    return result;
  }
}
