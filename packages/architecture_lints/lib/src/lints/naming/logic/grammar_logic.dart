import 'package:architecture_lints/src/engines/language/language_analyzer.dart';
import 'package:architecture_lints/src/schema/enums/grammar_token.dart';
import 'package:architecture_lints/src/utils/architecture_logger.dart';
import 'package:architecture_lints/src/utils/extensions/string_extension.dart';

class GrammarResult {
  final bool isValid;
  final String? reason;
  final String? correction;

  const GrammarResult.valid() : isValid = true, reason = null, correction = null;

  const GrammarResult.invalid({required this.reason, required this.correction}) : isValid = false;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $reason';
}

mixin GrammarLogic {
  static const _tag = 'GrammarLogic';

  /// Validates [className] against a [grammar] string using the [analyzer].
  GrammarResult validateGrammar(String grammar, String className, LanguageAnalyzer analyzer) {
    ArchLogger.log('---------------------------------------------------', tag: _tag);
    ArchLogger.log('Checking Class: "$className" against Template: "$grammar"', tag: _tag);

    // 1. Extract Core Name
    final coreName = _extractCoreName(grammar, className);
    ArchLogger.log('Extracted Core Name: "$coreName"', tag: _tag);

    if (coreName.isEmpty) {
      ArchLogger.log('Core name empty. Returning Valid.', tag: _tag);
      return const GrammarResult.valid();
    }

    // 2. Split Words
    final words = coreName.splitPascalCase();
    ArchLogger.log('Split Words: $words', tag: _tag);

    if (words.isEmpty) return const GrammarResult.valid();

    // --- PRIORITY 1: ACTIONS (Verb-Noun) ---
    final hasVerb =
        GrammarToken.verb.isPresentIn(grammar) || GrammarToken.verbPresent.isPresentIn(grammar);
    final hasNoun =
        GrammarToken.noun.isPresentIn(grammar) || GrammarToken.nounPhrase.isPresentIn(grammar);

    if (hasVerb && hasNoun) {
      ArchLogger.log('Matched Logic: ACTION (Verb-Noun)', tag: _tag);

      if (words.length < 2) {
        ArchLogger.log('Fail: Name too short for Action', tag: _tag);
        return const GrammarResult.invalid(
          reason: 'The name is too short.',
          correction: 'Use the format Action + Subject (e.g., GetUser).',
        );
      }

      final firstWord = words.first;
      final isV = analyzer.isVerb(firstWord);
      ArchLogger.log('Checking First Word "$firstWord" isVerb? $isV', tag: _tag);

      if (!isV) {
        return GrammarResult.invalid(
          reason: 'The first word "$firstWord" is not a recognized Verb.',
          correction: 'Start with an action verb like Get, Save, or Load.',
        );
      }

      final lastWord = words.last;
      final isN = analyzer.isNoun(lastWord);
      ArchLogger.log('Checking Last Word "$lastWord" isNoun? $isN', tag: _tag);

      if (!isN) {
        return GrammarResult.invalid(
          reason: 'The last word "$lastWord" is not a recognized Noun (Subject).',
          correction: 'End with the subject being acted upon (e.g., User, Data).',
        );
      }
      return const GrammarResult.valid();
    }

    // --- PRIORITY 2: STATES (Adjective/Past/Gerund) ---
    final hasAdj = GrammarToken.adjective.isPresentIn(grammar);
    final hasGerund = GrammarToken.verbGerund.isPresentIn(grammar);
    final hasPast = GrammarToken.verbPast.isPresentIn(grammar);

    if (hasAdj || hasGerund || hasPast) {
      ArchLogger.log('Matched Logic: STATE', tag: _tag);

      final last = words.last;
      var match = false;

      if (hasAdj) {
        final isA = analyzer.isAdjective(last);
        ArchLogger.log('Check "$last" isAdjective? $isA', tag: _tag);
        if (isA) match = true;
      }
      if (!match && hasGerund) {
        final isG = analyzer.isVerbGerund(last);
        ArchLogger.log('Check "$last" isVerbGerund? $isG', tag: _tag);
        if (isG) match = true;
      }
      if (!match && hasPast) {
        final isP = analyzer.isVerbPast(last);
        ArchLogger.log('Check "$last" isVerbPast? $isP', tag: _tag);
        if (isP) match = true;
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
    final hasNounToken =
        GrammarToken.noun.isPresentIn(grammar) ||
        GrammarToken.nounPhrase.isPresentIn(grammar) ||
        GrammarToken.nounSingular.isPresentIn(grammar) ||
        GrammarToken.nounPlural.isPresentIn(grammar);

    if (hasNounToken) {
      ArchLogger.log('Matched Logic: NOUN PHRASE', tag: _tag);

      final head = words.last;
      final isNoun = analyzer.isNoun(head);
      final isVerb = analyzer.isVerb(head);
      ArchLogger.log('Checking Head "$head". isNoun: $isNoun, isVerb: $isVerb', tag: _tag);

      // A. Strict POS Check on Head Noun
      if (!isNoun) {
        if (isVerb) {
          return GrammarResult.invalid(
            reason: 'The subject "$head" seems to be a Verb (Action).',
            correction: 'Ensure the name describes a specific Object.',
          );
        }
      }

      // B. Plurality Check
      if (GrammarToken.nounPlural.isPresentIn(grammar) && !analyzer.isNounPlural(head)) {
        ArchLogger.log('Fail: "$head" is not plural', tag: _tag);
        return const GrammarResult.invalid(
          reason: 'Subject is not a Plural Noun.',
          correction: 'Use a plural noun.',
        );
      }
      if (GrammarToken.nounSingular.isPresentIn(grammar) && !analyzer.isNounSingular(head)) {
        ArchLogger.log('Fail: "$head" is not singular', tag: _tag);
        return const GrammarResult.invalid(
          reason: 'Subject is not a Singular Noun.',
          correction: 'Use a singular noun.',
        );
      }

      // C. Modifier Check
      ArchLogger.log('Checking Modifiers: ${words.sublist(0, words.length - 1)}', tag: _tag);
      for (var i = 0; i < words.length - 1; i++) {
        final word = words[i];
        final isGerund = analyzer.isVerbGerund(word);
        ArchLogger.log('  > "$word" isGerund? $isGerund', tag: _tag);

        if (isGerund) {
          ArchLogger.log('VIOLATION FOUND: Gerund modifier', tag: _tag);
          return GrammarResult.invalid(
            reason: '"$word" is a Gerund (action), but this component should be a static Noun.',
            correction: 'Remove "$word" or change it to a descriptive adjective.',
          );
        }
      }
      return const GrammarResult.valid();
    }

    ArchLogger.log('No specific logic matched for grammar tokens.', tag: _tag);
    return const GrammarResult.valid();
  }

  String _extractCoreName(String grammar, String className) {
    var regexStr = RegExp.escape(grammar);

    for (final token in GrammarToken.values) {
      // Escape the token template (e.g. \$\{noun\})
      final escapedTemplate = RegExp.escape(token.template);
      // Replace with capturing group
      regexStr = regexStr.replaceAll(escapedTemplate, '(.*)');
    }

    final regex = RegExp('^$regexStr\$');
    final match = regex.firstMatch(className);

    if (match != null) {
      final buffer = StringBuffer();
      for (var i = 1; i <= match.groupCount; i++) {
        buffer.write(match.group(i) ?? '');
      }
      return buffer.toString();
    }
    return className;
  }
}
