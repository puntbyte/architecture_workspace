// lib/src/utils/json_map_extension.dart

/// An extension on `Map<String, dynamic>` to provide safe, reusable methods
/// for parsing configuration values from a YAML file.
extension JsonMapExtension on Map<String, dynamic> {
  /// Safely retrieves a nested map for a given [key].
  ///
  /// If the value for the key is not a map or is null, this returns an
  /// empty map, preventing runtime errors.
  Map<String, dynamic> getMap(String key) {
    final value = this[key];
    if (value is Map<String, dynamic>) return value;
    // Handle cases where the parser returns a generic Map.
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  /// Safely retrieves a list of strings for a given [key].
  ///
  /// This method is flexible and can handle three cases from the YAML:
  /// 1. The value is a valid `List<String>`.
  /// 2. The value is a single `String`, which will be wrapped in a list.
  /// 3. The value is missing, null, or another type, in which case it returns `orElse`.
  List<String> getList(String key, {List<String> orElse = const []}) {
    final value = this[key];

    // Case 1: The value is already a valid list of strings.
    if (value is List && value.every((item) => item is String)) {
      return value.cast<String>().toList();
    }

    // Case 2: The value is a single string. Wrap it in a list.
    if (value is String) {
      return [value];
    }

    // Case 3: Fallback for all other invalid cases.
    return orElse;
  }

  /// Safely retrieves a string for a given [key], falling back to a default.
  ///
  /// If the value for the key is not a string or is null, this returns the
  /// provided [orElse] value.
  String getString(String key, {String orElse = ''}) {
    final value = this[key];
    if (value is String) return value;
    return orElse;
  }

  /// Safely retrieves a string for a given [key], returning null if it's
  /// missing or not a string. This is for truly optional properties.
  String? getOptionalString(String key) {
    final value = this[key];
    if (value is String) return value;
    return null;
  }

  /// Safely retrieves a boolean for a given [key], falling back to a default.
  ///
  /// If the value for the key is not a boolean or is null, this returns the
  /// provided [orElse] value, which defaults to `false`.
  bool getBool(String key, {bool orElse = false}) {
    final value = this[key];
    if (value is bool) return value;
    return orElse;
  }
}
