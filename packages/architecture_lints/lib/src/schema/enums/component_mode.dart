// lib/src/config/enums/component_model.dart

import 'package:collection/collection.dart';

enum ComponentMode {
  /// The component owns the file (1-to-1 mapping).
  /// This is the default. e.g. 'user_entity.dart' -> 'Entity'.
  file('file'),

  /// The component is a symbol defined inside another file.
  /// e.g. 'class _UserParams' inside 'user_usecase.dart'.
  part('part'),

  /// The component is a logical container/folder. It should NOT match a specific file directly.
  /// Used for grouping (e.g. 'domain', 'data').
  namespace('namespace')
  ;

  final String yamlKey;

  const ComponentMode(this.yamlKey);

  static ComponentMode fromKey(String? key) =>
      ComponentMode.values.firstWhereOrNull((mode) => mode.yamlKey == key) ?? ComponentMode.file;
}
