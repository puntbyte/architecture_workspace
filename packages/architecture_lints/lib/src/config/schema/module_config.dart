// lib/src/config/schema/module_config.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ModuleConfig {
  final String key;
  final String path;
  final bool isDefault;
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

      path = map.getString(ConfigKeys.module.path);
      isDefault = map.getBool(ConfigKeys.module.default$);

      // Check for strict key existence before getting bool
      if (map.containsKey(ConfigKeys.module.strict)) {
        strict = map[ConfigKeys.module.strict] as bool;
      }
    } else {
      throw FormatException('Invalid module config for $key');
    }

    final defaultStrict = path.contains('{{name}}') || path.contains('*');

    return ModuleConfig(
      key: key,
      path: path,
      isDefault: isDefault,
      strict: strict ?? defaultStrict,
    );
  }

  static List<ModuleConfig> parseMap(Map<String, dynamic> map) =>
      map.entries.map((e) => ModuleConfig.fromMap(e.key, e.value)).toList();
}
