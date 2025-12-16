import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class VocabularyDefinition {
  final Set<String> nouns;
  final Set<String> verbs;
  final Set<String> adjectives;

  const VocabularyDefinition({
    this.nouns = const {},
    this.verbs = const {},
    this.adjectives = const {},
  });

  factory VocabularyDefinition.fromMap(Map<dynamic, dynamic> map) => VocabularyDefinition(
    nouns: _parseSet(map, ConfigKeys.vocabulary.nouns),
    verbs: _parseSet(map, ConfigKeys.vocabulary.verbs),
    adjectives: _parseSet(map, ConfigKeys.vocabulary.adjectives),
  );

  static Set<String> _parseSet(Map<dynamic, dynamic> map, String key) {
    final list = map.getStringList(key);
    // Normalize to lowercase for matching
    return list.map((e) => e.toLowerCase()).toSet();
  }

  bool get isEmpty => nouns.isEmpty && verbs.isEmpty && adjectives.isEmpty;
}
