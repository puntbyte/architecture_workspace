import 'package:architecture_lints/src/engines/language/language_analyzer.dart';
import 'package:architecture_lints/src/schema/enums/grammar_token.dart';
import 'package:architecture_lints/src/utils/architecture_logger.dart';
import 'package:architecture_lints/src/utils/extensions/string_extension.dart';

mixin GrammarLogic {
  static const _tag = 'GrammarLogic';

  GrammarResult validateGrammar(
    String grammar,
    String className,
    LanguageAnalyzer analyzer,
  ) {
    ArchLogger.log('Checking "$className" against "$grammar"', tag: _tag);

    final coreName = _extractCoreName(grammar, className);
    ArchLogger.log('Extracted Core Name: "$coreName"', tag: _tag);

    if (coreName.isEmpty) return const GrammarResult.valid();

    final words = coreName.splitPascalCase();
    ArchLogger.log('Split Words: $words', tag: _tag);

    if (words.isEmpty) return const GrammarResult.valid();

    // --- PRIORITY 1: ACTIONS (Verb-Noun or Verb Phrase) ---
    final hasVerbToken =
        GrammarToken.verb.isPresentIn(grammar) ||
        GrammarToken.verbPhrase.isPresentIn(grammar) ||
        GrammarToken.verbPresent.isPresentIn(grammar) ||
        GrammarToken.verbPresentPhrase.isPresentIn(grammar) ||
        GrammarToken.verbPast.isPresentIn(grammar) ||
        GrammarToken.verbPastPhrase.isPresentIn(grammar);

    final hasNounToken =
        GrammarToken.noun.isPresentIn(grammar) ||
        GrammarToken.nounPhrase.isPresentIn(grammar) ||
        GrammarToken.nounSingular.isPresentIn(grammar) ||
        GrammarToken.nounSingularPhrase.isPresentIn(grammar) ||
        GrammarToken.nounPlural.isPresentIn(grammar) ||
        GrammarToken.nounPluralPhrase.isPresentIn(grammar);

    if (hasVerbToken && hasNounToken) {
      ArchLogger.log('Matched Logic: ACTION (Verb/Noun Phrase)', tag: _tag);

      // Heuristic: If it has both, we expect a verb phrase modifying a noun phrase.
      // E.g., "GetUser", "GetUserData"

      final result = _validateVerbNounPhrase(words, analyzer, grammar);
      if (!result.isValid) return result;
      return const GrammarResult.valid();
    }

    // --- PRIORITY 2: STATES (Adjective/Past/Gerund) ---
    final hasStateToken =
        GrammarToken.adjective.isPresentIn(grammar) ||
        GrammarToken.verbGerund.isPresentIn(grammar) ||
        GrammarToken.verbPast.isPresentIn(grammar);

    if (hasStateToken) {
      ArchLogger.log('Matched Logic: STATE', tag: _tag);

      final last = words.last;
      var match = false;

      if (GrammarToken.adjective.isPresentIn(grammar) && analyzer.isAdjective(last)) match = true;
      if (!match && GrammarToken.verbGerund.isPresentIn(grammar) && analyzer.isVerbGerund(last)) {
        match = true;
      }
      if (!match && GrammarToken.verbPast.isPresentIn(grammar) && analyzer.isVerbPast(last)) {
        match = true;
      }

      if (!match) {
        return GrammarResult.invalid(
          reason: 'The suffix "$last" does not describe a valid State.',
          correction: 'States should end with an Adjective, Past Action, or Ongoing Action.',
        );
      }
      return const GrammarResult.valid();
    }

    // --- PRIORITY 3: OBJECTS (Noun Phrases) ---
    if (hasNounToken) {
      ArchLogger.log('Matched Logic: NOUN PHRASE', tag: _tag);

      final result = _validateNounPhrase(words, analyzer, grammar);
      if (!result.isValid) return result;
      return const GrammarResult.valid();
    }

    ArchLogger.log('No specific logic matched for grammar tokens.', tag: _tag);
    return const GrammarResult.valid();
  }

  // --- New Helpers for Phrase Validation ---

  GrammarResult _validateVerbNounPhrase(
    List<String> words,
    LanguageAnalyzer analyzer,
    String grammar,
  ) {
    // Simple Heuristic for VerbNoun: First part is Verb, Last part is Noun
    if (words.length < 2) {
      return const GrammarResult.invalid(
        reason: 'The name is too short for a Verb-Noun phrase.',
        correction: 'Use the format Action + Subject (e.g., GetUser).',
      );
    }

    // We try to split into a verb prefix and a noun phrase suffix
    // e.g., "Get" + "User" or "Get" + "All" + "Users"

    for (var i = 0; i < words.length - 1; i++) {
      final verbPart = words.sublist(0, i + 1);
      final nounPart = words.sublist(i + 1);

      var isV = false;

      // Check Verb Part
      if (GrammarToken.verbPhrase.isPresentIn(grammar) ||
          GrammarToken.verbPresentPhrase.isPresentIn(grammar)) {
        isV = analyzer.isVerbPhrase(verbPart);
      } else {
        // Simple Verb
        isV = verbPart.length == 1 && analyzer.isVerb(verbPart.first);
      }

      if (isV) {
        // Check Noun Part
        // We assume Noun Phrase logic applies to the tail
        final isN = analyzer.isNounPhrase(nounPart);
        if (isN) return const GrammarResult.valid();
      }
    }

    return const GrammarResult.invalid(
      reason: 'Name must start with a Verb (Action) and end with a Noun (Subject).',
      correction: 'Example: GetUser or LogOutUser.',
    );
  }

  GrammarResult _validateNounPhrase(
    List<String> words,
    LanguageAnalyzer analyzer,
    String grammar,
  ) {
    // 1. Basic Phrase Check
    if (!analyzer.isNounPhrase(words)) {
      final last = words.last;
      if (analyzer.isVerb(last)) {
        return GrammarResult.invalid(
          reason: 'Subject "$last" is a Verb.',
          correction: 'Use a Noun.',
        );
      }

      return const GrammarResult.invalid(
        reason: 'Not a valid Noun Phrase.',
        correction: 'Use Noun + Modifiers.',
      );
    }

    final head = words.last; // The actual noun

    // 2. Plurality
    if (GrammarToken.nounPlural.isPresentIn(grammar) ||
        GrammarToken.nounPluralPhrase.isPresentIn(grammar)) {
      if (!analyzer.isNounPlural(head)) {
        return GrammarResult.invalid(
          reason: 'Subject must be Plural.',
          correction: 'Change "$head" to plural.',
        );
      }
    }
    if (GrammarToken.nounSingular.isPresentIn(grammar) ||
        GrammarToken.nounSingularPhrase.isPresentIn(grammar)) {
      if (!analyzer.isNounSingular(head)) {
        return GrammarResult.invalid(
          reason: 'Subject must be Singular.',
          correction: 'Change "$head" to singular.',
        );
      }
    }

    // 3. Modifier Check
    // If not explicitly allowed, ban Gerunds in Noun Phrases
    for (var i = 0; i < words.length - 1; i++) {
      final word = words[i];
      if (analyzer.isVerbGerund(word)) {
        // Unless grammar allows gerunds explicitly?
        // For now, ban them in pure Noun Phrases (e.g. ParsingUser)
        return GrammarResult.invalid(
          reason: '"$word" is a Gerund.',
          correction: 'Use an adjective.',
        );
      }
    }

    return const GrammarResult.valid();
  }

  String _extractCoreName(String grammar, String className) {
    var regexStr = RegExp.escape(grammar);

    for (final token in GrammarToken.values) {
      final escapedTemplate = RegExp.escape(token.template);
      regexStr = regexStr.replaceAll(escapedTemplate, '(.*)');
    }

    final regex = RegExp('^$regexStr\$');
    final match = regex.firstMatch(className);

    if (match != null) {
      final buffer = StringBuffer();
      for (var index = 1; index <= match.groupCount; index++) {
        buffer.write(match.group(index) ?? '');
      }
      return buffer.toString();
    }
    return className;
  }
}

class GrammarResult {
  final bool isValid;
  final String? reason;
  final String? correction;

  const GrammarResult.valid() : isValid = true, reason = null, correction = null;

  const GrammarResult.invalid({required this.reason, required this.correction}) : isValid = false;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $reason';
}
