import 'package:collection/collection.dart';

enum RelationshipOperation {
  iteration('iteration')
  ;

  final String yamlKey;

  const RelationshipOperation(this.yamlKey);

  static RelationshipOperation? fromKey(String? key) =>
      RelationshipOperation.values.firstWhereOrNull((operation) => operation.yamlKey == key);
}
