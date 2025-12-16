import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/constraints/member_constraint.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class MemberPolicy {
  final List<String> onIds;
  final List<MemberConstraint> required;
  final List<MemberConstraint> allowed;
  final List<MemberConstraint> forbidden;

  const MemberPolicy({
    required this.onIds,
    required this.required,
    required this.allowed,
    required this.forbidden,
  });

  factory MemberPolicy.fromMap(Map<dynamic, dynamic> map) => MemberPolicy(
    onIds: map.getStringList(ConfigKeys.member.on),
    required: MemberConstraint.listFromDynamic(map[ConfigKeys.member.required]),
    allowed: MemberConstraint.listFromDynamic(map[ConfigKeys.member.allowed]),
    forbidden: MemberConstraint.listFromDynamic(map[ConfigKeys.member.forbidden]),
  );

  /// Parses the 'members' list.
  static List<MemberPolicy> parseList(List<Map<String, dynamic>> list) =>
      list.map(MemberPolicy.fromMap).toList();
}
