// lib/src/config/schema/usage_policy.dart

import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/constraints/usage_constraint.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class UsagePolicy {
  final List<String> onIds;
  final List<UsageConstraint> forbidden;

  const UsagePolicy({
    required this.onIds,
    required this.forbidden,
  });

  factory UsagePolicy.fromMap(Map<dynamic, dynamic> map) => UsagePolicy(
    onIds: map.getStringList(ConfigKeys.usage.on),
    forbidden: map.getMapList(ConfigKeys.usage.forbidden).map(UsageConstraint.fromMap).toList(),
  );

  /// Parses the 'usages' list.
  static List<UsagePolicy> parseList(List<Map<String, dynamic>> list) =>
      list.map(UsagePolicy.fromMap).toList();
}
