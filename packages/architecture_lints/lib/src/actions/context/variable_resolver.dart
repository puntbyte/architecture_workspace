import 'package:architecture_lints/src/actions/context/source_wrapper.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:expressions/expressions.dart';

class VariableResolver {
  final Map<String, dynamic> _context;
  final _evaluator = const ExpressionEvaluator();

  // FIX: Constructor now accepts config as a second argument
  VariableResolver(SourceWrapper source, ArchitectureConfig config)
      : _context = {
    'source': source,
    'config': config,
    'definitions': config.definitions,
  };

  /// Resolves the entire variables map recursively.
  Map<String, dynamic> resolveMap(Map<String, dynamic> variablesConfig) {
    final result = <String, dynamic>{};

    variablesConfig.forEach((key, value) {
      if (key.startsWith('.')) return;

      // 1. Resolve Expression Strings
      if (value is String) {
        try {
          final expression = Expression.parse(value);
          result[key] = _evaluator.eval(expression, _context);
        } catch (e) {
          result[key] = value;
        }
      }

      // 2. Handle Nested Objects / Lists logic (Recursive placeholder)
      if (value is Map<String, dynamic> && !key.startsWith('.')) {
        result[key] = resolveMap(value);
      }
    });

    return result;
  }
}