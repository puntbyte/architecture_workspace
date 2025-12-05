import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class SymbolDefinition {
  final List<String> types; // e.g. ['GetIt', 'Injector']
  final List<String> identifiers; // e.g. ['getIt', 'sl']
  final String? import;

  const SymbolDefinition({
    this.types = const [],
    this.identifiers = const [],
    this.import,
  });

  factory SymbolDefinition.fromMap(Map<dynamic, dynamic> map) {
    return SymbolDefinition(
      types: map.getStringList(ConfigKeys.service.type),
      identifiers: map.getStringList(ConfigKeys.service.identifier),
      import: map.tryGetString(ConfigKeys.service.import),
    );
  }

  /// Parses the 'services' map into a registry.
  static Map<String, SymbolDefinition> parseRegistry(Map<String, Map<String, dynamic>> map) {
    return map.map((key, value) => MapEntry(key, SymbolDefinition.fromMap(value)));
  }
}
