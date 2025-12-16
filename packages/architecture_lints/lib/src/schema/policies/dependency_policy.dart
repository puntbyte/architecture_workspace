import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/constraints/dependency_constraint.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class DependencyPolicy {
  /// The component IDs this rule applies to.
  final List<String> onIds;

  /// Whitelist rules.
  final DependencyConstraint allowed;

  /// Blacklist rules.
  final DependencyConstraint forbidden;

  const DependencyPolicy({
    required this.onIds,
    required this.allowed,
    required this.forbidden,
  });

  factory DependencyPolicy.fromMap(Map<dynamic, dynamic> map) => DependencyPolicy(
    onIds: map.getStringList(ConfigKeys.dependency.on),
    allowed: DependencyConstraint.fromDynamic(map[ConfigKeys.dependency.allowed]),
    forbidden: DependencyConstraint.fromDynamic(map[ConfigKeys.dependency.forbidden]),
  );

  /// Parses the 'dependencies' list.
  static List<DependencyPolicy> parseList(List<Map<String, dynamic>> list) =>
      list.map(DependencyPolicy.fromMap).toList();
}
