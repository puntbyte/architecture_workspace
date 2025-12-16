// lib/src/engines/variable/handlers/map_handler.dart

import 'package:architecture_lints/src/engines/variable/variable.dart';
import 'package:architecture_lints/src/schema/definitions/variable_definition.dart';

class MapHandler extends VariableHandler {
  const MapHandler(super.engine);

  @override
  dynamic handle(
    VariableDefinition config,
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
