// lib/src/config/enums/component_kind.dart

import 'package:collection/collection.dart';

enum ComponentKind {
  class$('class'),
  mixin$('mixin'),
  enum$('enum'),
  extension$('extension'),
  extensionType$('extension_type'),
  typedef$('typedef'),
  function('function'),
  variable('variable')
  ;

  final String yamlKey;
  const ComponentKind(this.yamlKey);

  static ComponentKind? fromKey(String? key) {
    return ComponentKind.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}
