import 'package:architecture_lints/src/engines/language/language_analyzer.dart';
import 'package:architecture_lints/src/schema/enums/grammar_token.dart';
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
  /// Validates [className] against a [grammar] string using the [analyzer].
  GrammarResult validateGrammar(String grammar, String className, LanguageAnalyzer analyzer) {
    print('\n[GrammarLogic] ---------------------------------------------------');
    print('[GrammarLogic] Checking Class: "$className" against Template: "$grammar"');

    // 1. Extract Core Name
    final coreName = _extractCoreName(grammar, className);
    print('[GrammarLogic] Extracted Core Name: "$coreName"');

    if (coreName.isEmpty) {
      print('[GrammarLogic] Core name empty. Returning Valid.');
      return const GrammarResult.valid();
    }

    // 2. Split Words
    final words = coreName.splitPascalCase();
    print('[GrammarLogic] Split Words: $words');

    if (words.isEmpty) return const GrammarResult.valid();

    // --- PRIORITY 1: ACTIONS (Verb-Noun) ---
    final hasVerb =
        GrammarToken.verb.isPresentIn(grammar) || GrammarToken.verbPresent.isPresentIn(grammar);
    final hasNoun =
        GrammarToken.noun.isPresentIn(grammar) || GrammarToken.nounPhrase.isPresentIn(grammar);

    if (hasVerb && hasNoun) {
      print('[GrammarLogic] Matched Logic: ACTION (Verb-Noun)');

      if (words.length < 2) {
        print('[GrammarLogic] Fail: Too short');
        return const GrammarResult.invalid(
          reason: 'The name is too short.',
          correction: 'Use the format Action + Subject (e.g., GetUser).',
        );
      }

      final firstWord = words.first;
      final isV = analyzer.isVerb(firstWord);
      print('[GrammarLogic] Checking First Word "$firstWord" isVerb? $isV');

      if (!isV) {
        return GrammarResult.invalid(
          reason: 'The first word "$firstWord" is not a recognized Verb.',
          correction: 'Start with an action verb like Get, Save, or Load.',
        );
      }

      final lastWord = words.last;
      final isN = analyzer.isNoun(lastWord);
      print('[GrammarLogic] Checking Last Word "$lastWord" isNoun? $isN');

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
      print('[GrammarLogic] Matched Logic: STATE');

      final last = words.last;
      var match = false;

      if (hasAdj) {
        final isA = analyzer.isAdjective(last);
        print('[GrammarLogic] Check "$last" isAdjective? $isA');
        if (isA) match = true;
      }
      if (!match && hasGerund) {
        final isG = analyzer.isVerbGerund(last);
        print('[GrammarLogic] Check "$last" isVerbGerund? $isG');
        if (isG) match = true;
      }
      if (!match && hasPast) {
        final isP = analyzer.isVerbPast(last);
        print('[GrammarLogic] Check "$last" isVerbPast? $isP');
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
      print('[GrammarLogic] Matched Logic: NOUN PHRASE');

      final head = words.last;
      final isNoun = analyzer.isNoun(head);
      final isVerb = analyzer.isVerb(head);
      print('[GrammarLogic] Checking Head "$head". isNoun: $isNoun, isVerb: $isVerb');

      // A. Strict POS Check on Head Noun
      if (!isNoun) {
        if (isVerb) {
          return GrammarResult.invalid(
            reason: 'The subject "$head" seems to be a Verb (Action).',
            correction: 'Ensure the name describes a specific Object.',
          );
        }
        // If unknown, we usually let it pass to avoid false positives on domain jargon
      }

      // B. Plurality Check
      if (GrammarToken.nounPlural.isPresentIn(grammar) && !analyzer.isNounPlural(head)) {
        return const GrammarResult.invalid(
          reason: 'Subject is not a Plural Noun.',
          correction: 'Use a plural noun.',
        );
      }
      if (GrammarToken.nounSingular.isPresentIn(grammar) && !analyzer.isNounSingular(head)) {
        return const GrammarResult.invalid(
          reason: 'Subject is not a Singular Noun.',
          correction: 'Use a singular noun.',
        );
      }

      // C. Modifier Check
      print('[GrammarLogic] Checking Modifiers: ${words.sublist(0, words.length - 1)}');
      for (var i = 0; i < words.length - 1; i++) {
        final word = words[i];
        final isGerund = analyzer.isVerbGerund(word);
        print('  > "$word" isGerund? $isGerund');

        if (isGerund) {
          print('[GrammarLogic] VIOLATION FOUND: Gerund modifier');
          return GrammarResult.invalid(
            reason: '"$word" is a Gerund (action), but this component should be a static Noun.',
            correction: 'Remove "$word" or change it to a descriptive adjective.',
          );
        }
      }
      return const GrammarResult.valid();
    }

    print('[GrammarLogic] No specific logic matched for grammar tokens.');
    return const GrammarResult.valid();
  }

  String _extractCoreName(String grammar, String className) {
    var regexStr = RegExp.escape(grammar);

    for (final token in GrammarToken.values) {
      // Note: GrammarToken.template usually returns {{...}}
      // Ensure we escape that for the regex replacer
      final escapedTemplate = RegExp.escape(token.template);

      // We replace the token with a capturing group (.*)
      // This is greedy, but for simple Prefix{{noun}}Suffix patterns it works.
      regexStr = regexStr.replaceAll(escapedTemplate, '(.*)');
    }

    final regex = RegExp('^$regexStr\$');
    // print('[GrammarLogic] Extraction Regex: $regex');

    final match = regex.firstMatch(className);

    if (match != null) {
      final buffer = StringBuffer();
      for (var i = 1; i <= match.groupCount; i++) {
        buffer.write(match.group(i) ?? '');
      }
      return buffer.toString();
    }

    // If regex fails (e.g. grammar is "{{noun}}Model" but class is "UserHelper"),
    // we assume the whole name is the subject to be analyzed.
    return className;
  }
}
