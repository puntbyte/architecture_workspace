import 'package:collection/collection.dart';

enum GrammarToken {
  // Nouns
  noun(r'${noun}', 'a Noun'),
  nounPhrase(r'${noun.phrase}', 'a Noun Phrase'),
  nounSingular(r'${noun.singular}', 'a Singular Noun'),
  nounPlural(r'${noun.plural}', 'a Plural Noun'),

  // Verbs
  verb(r'${verb}', 'a Verb'),
  verbPresent(r'${verb.present}', 'a Present Tense Verb'),
  verbPast(r'${verb.past}', 'a Past Tense Verb'),
  verbGerund(r'${verb.gerund}', 'a Gerund (action ending in -ing)'),

  // Adjectives
  adjective(r'${adjective}', 'an Adjective')
  ;

  final String template;
  final String description;

  const GrammarToken(this.template, this.description);

  static GrammarToken? fromString(String template) {
    return GrammarToken.values.firstWhereOrNull((e) => e.template == template);
  }

  /// Checks if a config string contains this token
  bool isPresentIn(String configString) => configString.contains(template);
}
