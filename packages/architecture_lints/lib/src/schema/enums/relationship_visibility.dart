import 'package:collection/collection.dart';

enum RelationshipVisibility {
  public('public'),
  private('private')
  ;

  final String yamlKey;

  const RelationshipVisibility(this.yamlKey);

  static RelationshipVisibility? fromKey(String? key) =>
      RelationshipVisibility.values.firstWhereOrNull((visibility) => visibility.yamlKey == key);
}
