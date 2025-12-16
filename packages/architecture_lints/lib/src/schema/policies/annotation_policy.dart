// lin/src/config/schema/annotation_policy.dart

import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/enums/annotation_mode.dart';
import 'package:architecture_lints/src/schema/constraints/annotation_constraint.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class AnnotationPolicy {
  final List<String> onIds;
  final AnnotationMode mode;
  final List<AnnotationConstraint> required;
  final List<AnnotationConstraint> allowed;
  final List<AnnotationConstraint> forbidden;

  const AnnotationPolicy({
    required this.onIds,
    required this.required,
    required this.allowed,
    required this.forbidden,
    this.mode = AnnotationMode.implicit,
  });

  factory AnnotationPolicy.fromMap(Map<dynamic, dynamic> map) => AnnotationPolicy(
    onIds: map.getStringList(ConfigKeys.annotation.on),
    mode: AnnotationMode.fromKey(map.tryGetString(ConfigKeys.annotation.mode)),
    required: AnnotationConstraint.listFromDynamic(map[ConfigKeys.annotation.required]),
    allowed: AnnotationConstraint.listFromDynamic(map[ConfigKeys.annotation.allowed]),
    forbidden: AnnotationConstraint.listFromDynamic(map[ConfigKeys.annotation.forbidden]),
  );

  /// Parses the 'annotations' list.
  static List<AnnotationPolicy> parseList(List<Map<String, dynamic>> list) =>
      list.map(AnnotationPolicy.fromMap).toList();
}
