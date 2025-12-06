import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class InheritanceConfig {
  final List<String> onIds;
  final List<Definition> required;
  final List<Definition> allowed;
  final List<Definition> forbidden;

  const InheritanceConfig({
    required this.onIds,
    required this.required,
    required this.allowed,
    required this.forbidden,
  });

  factory InheritanceConfig.fromMap(Map<dynamic, dynamic> map) {
    return InheritanceConfig(
      onIds: map.getStringList(ConfigKeys.inheritance.on),
      required: _parseDefinitionList(map[ConfigKeys.inheritance.required]),
      allowed: _parseDefinitionList(map[ConfigKeys.inheritance.allowed]),
      forbidden: _parseDefinitionList(map[ConfigKeys.inheritance.forbidden]),
    );
  }

  /// Parses a list of Maps into a list of InheritanceConfigs.
  static List<InheritanceConfig> parseList(List<Map<String, dynamic>> list) {
    return list.map(InheritanceConfig.fromMap).toList();
  }

  static List<Definition> _parseDefinitionList(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      return value.map(Definition.fromDynamic).toList();
    }

    // Allow single object/string shorthand (e.g. required: 'Entity')
    return [Definition.fromDynamic(value)];
  }
}