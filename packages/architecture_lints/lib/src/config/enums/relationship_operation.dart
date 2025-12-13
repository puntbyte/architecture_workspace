import 'package:collection/collection.dart';

enum RelationshipOperation {
  iteration('iteration');

  final String yamlKey;
  const RelationshipOperation(this.yamlKey);

  static RelationshipOperation? fromKey(String? key) {
    return RelationshipOperation.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}