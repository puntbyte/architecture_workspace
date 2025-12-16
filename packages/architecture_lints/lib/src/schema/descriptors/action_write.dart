// lib/src/schema/descriptors/action_write.dart

import 'package:architecture_lints/src/schema/enums/write_placement.dart';
import 'package:architecture_lints/src/schema/enums/write_strategy.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ActionWrite {
  final WriteStrategy strategy;
  final WritePlacement placement;
  final String? filename;

  const ActionWrite({
    this.strategy = WriteStrategy.file,
    this.placement = WritePlacement.end,
    this.filename,
  });

  /// Defensive factory: accepts a nullable map and returns a default ActionWrite
  /// when the map is null or missing keys.
  factory ActionWrite.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const ActionWrite();
    return ActionWrite(
      strategy: WriteStrategy.fromKey(map.tryGetString('strategy')) ?? WriteStrategy.file,
      placement: WritePlacement.fromKey(map.tryGetString('placement')) ?? WritePlacement.end,
      filename: map.tryGetString('filename'),
    );
  }
}
