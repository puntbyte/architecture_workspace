import 'package:collection/collection.dart';

enum WriteStrategy {
  /// Creates a new file (or overwrites if exists).
  file('file'),

  /// Injects code into an existing class/mixin/extension body.
  inject('inject'),

  /// Replaces an existing member (e.g. updating a method).
  replace('replace')
  ;

  final String yamlKey;

  const WriteStrategy(this.yamlKey);

  static WriteStrategy? fromKey(String? key) =>
      WriteStrategy.values.firstWhereOrNull((strategy) => strategy.yamlKey == key);
}
