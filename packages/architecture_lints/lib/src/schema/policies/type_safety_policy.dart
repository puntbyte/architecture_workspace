// lib/src/config/schema/type_safety_policy.dart

import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/constraints/type_safety_constraint.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class TypeSafetyPolicy {
  final List<String> onIds;
  final List<TypeSafetyConstraint> allowed;
  final List<TypeSafetyConstraint> forbidden;

  const TypeSafetyPolicy({
    required this.onIds,
    required this.allowed,
    required this.forbidden,
  });

  factory TypeSafetyPolicy.fromMap(Map<dynamic, dynamic> map) => TypeSafetyPolicy(
    onIds: map.getStringList(ConfigKeys.typeSafety.on),
    allowed: TypeSafetyConstraint.listFromDynamic(map[ConfigKeys.typeSafety.allowed]),
    forbidden: TypeSafetyConstraint.listFromDynamic(map[ConfigKeys.typeSafety.forbidden]),
  );

  /// Parses the 'type_safeties' list.
  static List<TypeSafetyPolicy> parseList(List<Map<String, dynamic>> list) =>
      list.map(TypeSafetyPolicy.fromMap).toList();
}
