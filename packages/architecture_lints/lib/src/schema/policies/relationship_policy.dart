import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/enums/relationship_kind.dart';
import 'package:architecture_lints/src/schema/enums/relationship_operation.dart';
import 'package:architecture_lints/src/schema/enums/relationship_visibility.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class RelationshipPolicy {
  final List<String> onIds;

  /// The type of AST node to match (class or method).
  final RelationshipKind? kind;

  final RelationshipVisibility visibility;
  final RelationshipOperation? operation;

  final String targetComponent;
  final String? action;

  const RelationshipPolicy({
    required this.onIds,
    required this.targetComponent,
    this.kind,
    this.visibility = RelationshipVisibility.public,
    this.operation,
    this.action,
  });

  factory RelationshipPolicy.fromMap(Map<dynamic, dynamic> map) {
    final reqMap = map.mustGetMap(ConfigKeys.relationship.required);

    return RelationshipPolicy(
      onIds: map.getStringList(ConfigKeys.relationship.on),

      // Rename 'element' to 'kind'
      kind: RelationshipKind.fromKey(map.tryGetString(ConfigKeys.relationship.kind)),

      // Use Enhanced Enum with default
      visibility:
          RelationshipVisibility.fromKey(
            map.tryGetString(ConfigKeys.relationship.visibility),
          ) ??
          RelationshipVisibility.public,

      operation: RelationshipOperation.fromKey(map.tryGetString(ConfigKeys.relationship.operation)),

      targetComponent: reqMap.mustGetString(ConfigKeys.relationship.component),
      action: reqMap.tryGetString(ConfigKeys.relationship.action),
    );
  }

  static List<RelationshipPolicy> parseList(List<Map<String, dynamic>> list) =>
      list.map(RelationshipPolicy.fromMap).toList();
}
