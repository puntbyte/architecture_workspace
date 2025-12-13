import 'package:collection/collection.dart';

enum RelationshipKind {
  /// YAML: 'class'
  class$('class'),

  /// YAML: 'method'
  method('method')
  ;

  final String yamlKey;

  const RelationshipKind(this.yamlKey);

  static RelationshipKind? fromKey(String? key) {
    return RelationshipKind.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}
