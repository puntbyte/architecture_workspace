// lib/src/utils/map_extensions.dart

extension MapExtensions on Map<dynamic, dynamic> {
  /// Safely retrieves a non-nullable String.
  /// Returns [fallback] if key is missing or value is not a String.
  String getString(String key, {String fallback = ''}) {
    final value = this[key];
    if (value is String) return value;
    return fallback;
  }

  /// Safely retrieves a nullable String.
  /// Returns null (or specific [fallback]) if key is missing or type matches.
  String? tryGetString(String key, {String? fallback}) {
    final value = this[key];
    if (value is String) return value;
    return fallback;
  }

  /// Safely retrieves a boolean.
  /// Useful for flags like 'default: true'.
  bool getBool(String key, {bool fallback = false}) {
    final value = this[key];
    if (value is bool) return value;
    return fallback;
  }

  /// Safely retrieves a List of Strings.
  /// Handles cases where YAML might define a single string but you want a list.
  /// e.g. path: "core" -> ["core"]
  List<String> getStringList(String key) {
    final value = this[key];

    // Filter out non-string elements to be safe
    if (value is List) return value.whereType<String>().toList();

    // Handle single string promoted to list
    if (value is String) return [value];

    return [];
  }

  /// Safely retrieves a List of Maps.
  /// Used for parsing lists of objects (e.g., rules configuration).
  ///
  /// Filters out items in the list that are not Maps.
  List<Map<String, dynamic>> getMapList(String key) {
    final value = this[key];

    if (value is List) {
      return value.whereType<Map>().map((item) {
        try {
          return Map<String, dynamic>.from(item);
        } catch (_) {
          // If a map inside the list has non-string keys, ignoring it is safer
          // than crashing the whole parser.
          return <String, dynamic>{};
        }
      }).where((map) => map.isNotEmpty).toList();
    }

    return [];
  }

  /// Safely retrieves a Map and casts it to <String, dynamic>.
  /// Returns an empty map if key is missing or wrong type.
  Map<String, dynamic> getMap(String key) {
    final value = this[key];

    // Check against the base Map type, because YamlMap is Map<dynamic, dynamic>
    if (value is Map) {
      try {
        // create a new typed Map from the dynamic one
        return Map<String, dynamic>.from(value);
      } catch (e) {
        // If keys aren't strings, return empty
        return {};
      }
    }
    return {};
  }

  /// Safely retrieves a Map of Maps.
  /// Used for nested configurations like `components: { domain: { ... } }`.
  ///
  /// - Skips entries where the key is not a String.
  /// - Skips entries where the value is not a Map.
  Map<String, Map<String, dynamic>> getMapMap(String key) {
    final value = this[key];

    if (value is Map) {
      final result = <String, Map<String, dynamic>>{};

      value.forEach((k, v) {
        // 1. Key must be String
        if (k is String) {
          // 2. Value must be Map
          if (v is Map) {
            try {
              result[k] = Map<String, dynamic>.from(v);
            } catch (_) {
              // Ignore malformed child maps
            }
          }
        }
      });

      return result;
    }

    return {};
  }
}