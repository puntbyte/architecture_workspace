import 'package:collection/collection.dart';

enum VariableType {
  string('string'),
  bool('bool'),
  number('number'),
  list('list'),
  set('set'),
  map('map'),
  dynamic('dynamic')
  ;

  final String yamlKey;

  const VariableType(this.yamlKey);

  static VariableType fromKey(String? key) =>
      VariableType.values.firstWhereOrNull((type) => type.yamlKey == key) ?? VariableType.dynamic;
}
