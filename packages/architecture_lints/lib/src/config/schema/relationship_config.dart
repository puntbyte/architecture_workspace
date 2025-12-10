import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/enums/relationship_element.dart'; // Import Enum
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class RelationshipConfig {
  final List<String> onIds;

  // Renamed from 'kind' and typed as Enum
  final RelationshipElement element;

  final String? visibility;
  final String? operation;
  final String targetComponent;
  final String? action;

  const RelationshipConfig({
    required this.onIds,
    required this.element,
    required this.targetComponent,
    this.operation,
    this.visibility = 'public',
    this.action,
  });

  factory RelationshipConfig.fromMap(Map<dynamic, dynamic> map) {
    final requiredMap = map.getMap(ConfigKeys.relationship.required);

    // Parse enum from string
    final elementKey = map.getString(ConfigKeys.relationship.kind, fallback: 'class');
    final element = RelationshipElement.fromKey(elementKey) ?? RelationshipElement.classElement;

    return RelationshipConfig(
      onIds: map.getStringList(ConfigKeys.relationship.on),
      element: element,
      visibility: map.getString(ConfigKeys.relationship.visibility, fallback: 'public'),
      operation: map.tryGetString(ConfigKeys.relationship.operation),

      targetComponent: requiredMap.mustGetString(ConfigKeys.relationship.component),
      action: requiredMap.tryGetString(ConfigKeys.relationship.action),
    );
  }

  /// Parses the 'relationships' list.
  static List<RelationshipConfig> parseList(List<Map<String, dynamic>> list) {
    return list.map(RelationshipConfig.fromMap).toList();
  }
}
