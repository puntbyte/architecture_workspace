import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';

class ConditionalHandler {
  final ExpressionEngine engine;

  ConditionalHandler(this.engine);

  VariableConfig? handle(List<VariableSelect> select, Map<String, dynamic> context) {
    print('[ConditionalHandler] Processing ${select.length} branches');

    for (var i = 0; i < select.length; i++) {
      final branch = select[i];
      final condition = branch.condition;

      // 1. Else / Fallback
      if (condition == null) {
        print('  [$i] Found ELSE branch. Returning result.');
        return branch.result;
      }

      // 2. If condition
      print('  [$i] Evaluating IF: "$condition"');
      try {
        // Inspect context before eval
        // final source = context['source'];
        // print('  [$i] Context Source Type: ${source.runtimeType}');

        final result = engine.evaluate(condition, context);
        print('  [$i] Result: $result (${result.runtimeType})');

        if (result == true) {
          print('  [$i] MATCH! Returning result.');
          return branch.result;
        }
      } catch (e, stack) {
        print('  [$i] EVAL ERROR: $e');
        // print(stack);
        // Continue to next branch on error
        continue;
      }
    }

    print('[ConditionalHandler] No branches matched. Returning null.');
    return null;
  }
}