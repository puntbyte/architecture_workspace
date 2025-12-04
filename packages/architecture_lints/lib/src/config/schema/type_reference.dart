import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class TypeReference {
  /// Raw class names (e.g., ['StatefulWidget', 'HookWidget']).
  final List<String> types;

  /// Strict package URI (e.g., 'package:flutter/widgets.dart').
  final String? import;

  /// Reference to a key in the `types` definitions (future feature).
  final List<String> definitions;

  /// Reference to an architectural component (e.g., 'port').
  /// Requires the target class to belong to this component layer.
  final String? component;

  const TypeReference({
    this.types = const [],
    this.import,
    this.definitions = const [],
    this.component,
  });

  factory TypeReference.empty() => const TypeReference();

  factory TypeReference.fromDynamic(dynamic value) {
    if (value == null) return TypeReference.empty();

    // Case 1: Simple String -> Class Name
    if (value is String) {
      return TypeReference(types: [value]);
    }

    // Case 2: List of Strings -> List of Class Names
    if (value is List) {
      return TypeReference(types: value.map((e) => e.toString()).toList());
    }

    // Case 3: Detailed Map
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      return TypeReference(
        types: map.getStringList(ConfigKeys.inheritance.type),
        import: map.tryGetString(ConfigKeys.inheritance.import),
        definitions: map.getStringList(ConfigKeys.inheritance.definition),
        component: map.tryGetString(ConfigKeys.inheritance.component),
      );
    }

    return TypeReference.empty();
  }

  bool get isEmpty => types.isEmpty && definitions.isEmpty && component == null;
  bool get isNotEmpty => !isEmpty;
}
