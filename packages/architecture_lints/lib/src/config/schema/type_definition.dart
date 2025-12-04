import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class TypeDefinition {
  final String type;
  final String? import;

  const TypeDefinition({
    required this.type,
    this.import,
  });

  /// Parses a definition value which can be a String or a Map.
  /// [currentImport] is used for "Cascading Imports" (inheriting import from previous sibling).
  factory TypeDefinition.fromDynamic(dynamic value, {String? currentImport}) {
    // Case 1: Shorthand String -> 'UnaryUsecase'
    if (value is String) {
      return TypeDefinition(type: value, import: currentImport);
    }

    // Case 2: Detailed Map -> { type: '...', import: '...' }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      final explicitImport = map.tryGetString(ConfigKeys.typeDef.import);
      final typeName = map.getString(ConfigKeys.typeDef.type);

      return TypeDefinition(
        type: typeName,
        // Use explicit import if present, otherwise fallback to cascading import
        import: explicitImport ?? currentImport,
      );
    }

    throw FormatException('Invalid type definition: $value');
  }
}