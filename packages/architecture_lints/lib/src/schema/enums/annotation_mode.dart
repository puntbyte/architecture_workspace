// lib/src/common/annotation_mode.dart

import 'package:collection/collection.dart';

enum AnnotationMode {
  strict('strict'),
  implicit('implicit')
  ;

  final String yamlKey;

  const AnnotationMode(this.yamlKey);

  static AnnotationMode fromKey(String? key) =>
      AnnotationMode.values.firstWhereOrNull((mode) => mode.yamlKey == key) ??
      AnnotationMode.implicit;
}
