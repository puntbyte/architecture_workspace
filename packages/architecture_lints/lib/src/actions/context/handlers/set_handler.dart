// lib/src/actions/context/handlers/set_handler.dart

import 'package:architecture_lints/src/actions/context/handlers/variable_handler.dart';
import 'package:architecture_lints/src/actions/context/helpers/import_extractor.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';

class SetHandler extends VariableHandler {
  final ImportExtractor extractor;

  const SetHandler(super.engine, this.extractor);

  @override
  dynamic handle(
    VariableConfig config,
    Map<String, dynamic> context,
    VariableResolver resolver,
  ) {
    // Sets are primarily used for Imports in this system,
    // so we use the Extractor to flatten everything into unique strings.
    final uniqueItems = <String>{};

    void add(dynamic val) => extractor.extract(val, uniqueItems);

    // 1. From
    if (config.from != null) {
      final source = engine.evaluate(config.from!, context);
      add(source);
    }

    // 2. Values
    for (final expr in config.values) {
      final val = engine.evaluate(expr, context);
      add(val);
    }

    // 3. Spread
    for (final expr in config.spread) {
      final val = engine.evaluate(expr, context);
      add(val);
    }

    final list = uniqueItems.toList()..sort();
    return buildListMeta(list);
  }
}
