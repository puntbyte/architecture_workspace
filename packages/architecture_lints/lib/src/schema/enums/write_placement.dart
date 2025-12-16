import 'package:collection/collection.dart';

enum WritePlacement {
  /// At the start of the block (e.g. after `{`).
  start('start'),

  /// At the end of the block (e.g. before `}`).
  end('end')
  ;

  final String yamlKey;

  const WritePlacement(this.yamlKey);

  static WritePlacement? fromKey(String? key) =>
      WritePlacement.values.firstWhereOrNull((placement) => placement.yamlKey == key);
}
