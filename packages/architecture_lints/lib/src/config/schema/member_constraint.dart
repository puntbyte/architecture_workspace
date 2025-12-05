import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/enums/member_kind.dart';
import 'package:architecture_lints/src/config/enums/member_modifier.dart';
import 'package:architecture_lints/src/config/enums/member_visibility.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class MemberConstraint {
  final MemberKind? kind;
  final List<String> identifiers;
  final MemberVisibility? visibility;
  final MemberModifier? modifier;

  const MemberConstraint({
    this.kind,
    this.identifiers = const [],
    this.visibility,
    this.modifier,
  });

  factory MemberConstraint.fromMap(Map<dynamic, dynamic> map) {
    final rawId = map[ConfigKeys.member.identifier];
    final ids = <String>[];
    if (rawId is String) ids.add(rawId);
    if (rawId is List) ids.addAll(rawId.map((e) => e.toString()));

    return MemberConstraint(
      kind: MemberKind.fromKey(map.tryGetString(ConfigKeys.member.kind)),
      identifiers: ids,
      visibility: MemberVisibility.fromKey(map.tryGetString(ConfigKeys.member.visibility)),
      modifier: MemberModifier.fromKey(map.tryGetString(ConfigKeys.member.modifier)),
    );
  }

  static List<MemberConstraint> listFromDynamic(dynamic value) {
    if (value is Map) return [MemberConstraint.fromMap(value)];

    if (value is List) return value.whereType<Map>().map(MemberConstraint.fromMap).toList();

    return [];
  }
}
