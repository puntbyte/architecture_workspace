import 'package:collection/collection.dart';

enum RelationshipVisibility {
  public('public'),
  private('private');

  final String yamlKey;
  const RelationshipVisibility(this.yamlKey);

  static RelationshipVisibility? fromKey(String? key) {
    return RelationshipVisibility.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}