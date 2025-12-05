import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/detail/dependency_detail.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class DependencyConfig {
  /// The component IDs this rule applies to.
  final List<String> onIds;

  /// Whitelist rules.
  final DependencyDetail allowed;

  /// Blacklist rules.
  final DependencyDetail forbidden;

  const DependencyConfig({
    required this.onIds,
    required this.allowed,
    required this.forbidden,
  });

  factory DependencyConfig.fromMap(Map<dynamic, dynamic> map) {
    return DependencyConfig(
      onIds: map.getStringList(ConfigKeys.dependency.on),
      allowed: DependencyDetail.fromDynamic(map[ConfigKeys.dependency.allowed]),
      forbidden: DependencyDetail.fromDynamic(map[ConfigKeys.dependency.forbidden]),
    );
  }

  /// Parses the 'dependencies' list.
  static List<DependencyConfig> parseList(List<Map<String, dynamic>> list) {
    return list.map(DependencyConfig.fromMap).toList();
  }
}
