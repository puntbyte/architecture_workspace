// lib/src/engines/variable/handlers/conditional_handler.dart

import 'package:architecture_lints/src/engines/expression/expression.dart';
import 'package:architecture_lints/src/schema/definitions/variable_definition.dart';
import 'package:architecture_lints/src/schema/descriptors/variable_select.dart';

class ConditionalHandler {
  final ExpressionEngine engine;

  ConditionalHandler(this.engine);

  VariableDefinition? handle(List<VariableSelect> select, Map<String, dynamic> context) {
    for (var i = 0; i < select.length; i++) {
      final branch = select[i];
      final condition = branch.condition;

      // 1. Else / Fallback
      if (condition == null) return branch.result;

      // 2. If condition
      try {
        // Inspect context before eval
        // final source = context['source'];
        // print('  [$i] Context Source Type: ${source.runtimeType}');

        final result = engine.evaluate(condition, context);

        if (result == true) return branch.result;
      } catch (e, stack) {
        // print(stack);
        // Continue to next branch on error
        continue;
      }
    }

    return null;
  }
}
