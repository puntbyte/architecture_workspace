// lib/src/schema/enums/grammar_token.dart

import 'package:architecture_lints/src/utils/token_syntax.dart';
import 'package:collection/collection.dart';

enum GrammarToken {
  // Nouns
  noun('a Noun'),
  nounPhrase('a Noun Phrase'),
  nounSingular('a Singular Noun'),
  nounSingularPhrase('a Singular Noun Phrase'),
  nounPlural('a Plural Noun'),
  nounPluralPhrase('a Plural Noun Phrase'),

  // Verbs
  verb('a Verb'),
  verbPhrase('a Verb Phrase'),
  verbPresent('a Present Tense Verb'),
  verbPresentPhrase('a Present Tense Verb Phrase'),
  verbPast('a Past Tense Verb'),
  verbPastPhrase('a Past Tense Verb Phrase'),
  verbGerund('a Gerund (action ending in -ing)'),

  // Other
  adjective('an Adjective'),
  adverb('an Adverb'),
  conjunction('a Conjunction'),
  preposition('a Preposition'),
  ;

  final String description;

  const GrammarToken(this.description);

  static GrammarToken? fromString(String template) =>
      GrammarToken.values.firstWhereOrNull((token) => token.template == template);

  String get template => switch (this) {
    GrammarToken.noun => TokenSyntax.wrap('noun'),
    GrammarToken.nounPhrase => TokenSyntax.wrap('noun.phrase'),
    GrammarToken.nounSingular => TokenSyntax.wrap('noun.singular'),
    GrammarToken.nounSingularPhrase => TokenSyntax.wrap('noun.singular.phrase'),
    GrammarToken.nounPlural => TokenSyntax.wrap('noun.plural'),
    GrammarToken.nounPluralPhrase => TokenSyntax.wrap('noun.plural.phrase'),

    GrammarToken.verb => TokenSyntax.wrap('verb'),
    GrammarToken.verbPhrase => TokenSyntax.wrap('verb.phrase'),
    GrammarToken.verbPresent => TokenSyntax.wrap('verb.present'),
    GrammarToken.verbPresentPhrase => TokenSyntax.wrap('verb.present.phrase'),
    GrammarToken.verbPast => TokenSyntax.wrap('verb.past'),
    GrammarToken.verbPastPhrase => TokenSyntax.wrap('verb.past.phrase'),
    GrammarToken.verbGerund => TokenSyntax.wrap('verb.gerund'),

    GrammarToken.adjective => TokenSyntax.wrap('adjective'),
    GrammarToken.adverb => TokenSyntax.wrap('adverb'),
    GrammarToken.conjunction => TokenSyntax.wrap('conjunction'),
    GrammarToken.preposition => TokenSyntax.wrap('preposition'),
  };

  /// Checks if a config string contains this token
  bool isPresentIn(String configString) => configString.contains(template);
}
