import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/enums/variable_type.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class VariableConfig {
  final VariableType type;

  // --- Primitive Props ---
  final String? value; // Expression

  // --- Logic Props ---
  final List<VariableSelect> select;

  // --- Collection Props ---
  final String? from; // Expression for Iterable
  final List<String> values; // List of expressions
  final List<String> spread; // List of expressions (Maps/Lists to merge)

  // --- Recursion Props ---
  /// Schema for mapping list items. Derived from the 'map' property.
  final Map<String, VariableConfig> mapSchema;

  /// Nested variables. Derived from keys starting with '.'.
  final Map<String, VariableConfig> children;

  final String? transformer;

  const VariableConfig({
    required this.type,
    this.value,
    this.select = const [],
    this.from,
    this.values = const [],
    this.spread = const [],
    this.mapSchema = const {},
    this.children = const {},
    this.transformer,
  });

  factory VariableConfig.fromDynamic(dynamic input) {
    // 1. Shorthand String -> Dynamic Expression
    if (input is String) return VariableConfig(type: VariableType.dynamic, value: input);

    // 2. Map Configuration
    if (input is Map) {
      final map = Map<String, dynamic>.from(input);

      // Parse Type
      final type = VariableType.fromKey(map.tryGetString('type'));

      // Parse Children (Keys starting with .)
      final children = <String, VariableConfig>{};
      final properties = <String, dynamic>{};

      map.forEach((key, val) {
        if (key.startsWith('.')) {
          children[key.substring(1)] = VariableConfig.fromDynamic(val);
        } else {
          properties[key] = val;
        }
      });

      // Parse 'map' schema for Lists
      final rawMapSchema = properties['map'];
      final mapSchema = <String, VariableConfig>{};
      if (rawMapSchema is Map) {
        rawMapSchema.forEach((k, v) {
          // In the 'map' property, we allow keys with OR without dots
          // to map to the output object, but stripping dots is safer for consistency.
          final cleanKey = k.toString().startsWith('.') ? k.toString().substring(1) : k.toString();
          mapSchema[cleanKey] = VariableConfig.fromDynamic(v);
        });
      }

      return VariableConfig(
        type: type,
        value: properties.tryGetString('value'),
        from: properties.tryGetString('from'),
        values: properties.getStringList('values'),
        spread: properties.getStringList('spread'),
        select: _parseSelect(properties['select']),
        transformer: map.tryGetString('transformer'),
        mapSchema: mapSchema,
        children: children,
      );
    }

    // Fallback
    return const VariableConfig(type: VariableType.dynamic);
  }

  static List<VariableSelect> _parseSelect(dynamic raw) {
    if (raw is List) return raw.map((e) => VariableSelect.fromMap(e as Map)).toList();
    return [];
  }
}

@immutable
class VariableSelect {
  final String? condition; // 'if'
  final VariableConfig result; // 'then' / 'value' / 'else'

  const VariableSelect({required this.result, this.condition});

  factory VariableSelect.fromMap(Map<dynamic, dynamic> map) {
    final condition = map.tryGetString('if');

    // The result can be in 'then', 'value', or 'else'.
    // We treat the value as a sub-config (so it can be complex).
    final rawResult = map['then'] ?? map['value'] ?? map['else'];

    return VariableSelect(
      condition: condition,
      result: VariableConfig.fromDynamic(rawResult),
    );
  }
}
