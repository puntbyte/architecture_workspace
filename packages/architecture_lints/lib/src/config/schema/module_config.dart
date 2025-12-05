import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ModuleConfig {
  final String key;
  final String path;
  final bool isDefault;

  /// If true, instances of this module cannot import other instances of the same module.
  /// Example: 'features/auth' cannot import 'features/home'.
  final bool strict;

  const ModuleConfig({
    required this.key,
    required this.path,
    this.isDefault = false,
    this.strict = true,
  });

  factory ModuleConfig.fromMap(String key, dynamic value) {
    String path;
    var isDefault = false;
    bool? strict;

    if (value is String) {
      path = value;
    } else if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      path = map.getString('path');
      isDefault = map.getBool('default');
      strict = map.getBool('strict');
      // Note: We can't easily detect "null" via getBool with fallback,
      // so we might check map.containsKey('strict') if we want smarter defaults below.
      if (map.containsKey('strict')) {
        strict = map['strict'] as bool;
      }
    } else {
      throw FormatException('Invalid module config for $key');
    }

    // Smart Default: If path contains wildcard, assume strict isolation is desired
    // unless explicitly disabled.
    // Static modules (e.g. 'core') don't need strict isolation from themselves.
    final defaultStrict = path.contains('{{name}}') || path.contains('*');

    return ModuleConfig(
      key: key,
      path: path,
      isDefault: isDefault,
      strict: strict ?? defaultStrict,
    );
  }

  /// Parses the 'modules' map.
  static List<ModuleConfig> parseMap(Map<String, dynamic> map) {
    return map.entries.map((e) => ModuleConfig.fromMap(e.key, e.value)).toList();
  }
}
