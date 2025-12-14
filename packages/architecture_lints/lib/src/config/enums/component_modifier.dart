// lib/src/config/enums/component_modifier.dart

import 'package:collection/collection.dart';

enum ComponentModifier {
  abstract('abstract'),
  sealed('sealed'),
  base('base'),
  interface('interface'),
  final$('final'),
  mixin('mixin')
  ;

  final String yamlKey;

  const ComponentModifier(this.yamlKey);

  static ComponentModifier? fromKey(String? key) =>
      ComponentModifier.values.firstWhereOrNull((modifier) => modifier.yamlKey == key);
}
