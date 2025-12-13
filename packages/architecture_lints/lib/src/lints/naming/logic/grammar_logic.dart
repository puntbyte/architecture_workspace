import 'package:architecture_lints/src/config/constants/grammar_token.dart';
import 'package:architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:architecture_lints/src/utils/nlp/language_analyzer.dart';

mixin GrammarLogic {
  /// Validates [className] against a [grammar] string using the [analyzer].
  GrammarResult validateGrammar(String grammar, String className, LanguageAnalyzer analyzer) {
    // 1. Extract Core Name (Remove Prefixes/Suffixes defined in grammar)
    // e.g. Grammar: "${noun}Repository", Class: "UserRepository" -> Core: "User"
    final coreName = _extractCoreName(grammar, className);

    if (coreName.isEmpty) return const GrammarResult.valid();

    final words = coreName.splitPascalCase();
    if (words.isEmpty) return const GrammarResult.valid();

    // --- CASE 1: Verb-Noun (UseCase style: "GetUser") ---
    // Triggered if grammar contains both Verb and Noun tokens
    if (GrammarToken.verb.isPresentIn(grammar) || GrammarToken.verbPresent.isPresentIn(grammar)) {
      // If it also requires a noun (Action + Subject)
      if (GrammarToken.noun.isPresentIn(grammar) || GrammarToken.nounPhrase.isPresentIn(grammar)) {
        if (words.length < 2) {
          return const GrammarResult.invalid(
            reason: 'The name is too short.',
            correction: 'Use the format Action + Subject (e.g., GetUser).',
          );
        }

        final firstWord = words.first;
        if (!analyzer.isVerb(firstWord)) {
          return GrammarResult.invalid(
            reason: 'The first word "$firstWord" is not a recognized Verb.',
            correction: 'Start with an action verb like Get, Save, or Load.',
          );
        }

        final lastWord = words.last;
        // Simple check: Last word should conceptually be a noun (Subject)
        if (!analyzer.isNoun(lastWord)) {
          // Pass if unknown, fail only if definitely not noun?
          // For strictness we fail.
          return GrammarResult.invalid(
            reason: 'The last word "$lastWord" is not a recognized Noun (Subject).',
            correction: 'End with the subject being acted upon (e.g., User, Data).',
          );
        }
        return const GrammarResult.valid();
      }
    }

    // --- CASE 2: Noun Phrase (Entity/Model style: "User", "PaymentMethod") ---
    if (GrammarToken.noun.isPresentIn(grammar) ||
        GrammarToken.nounPhrase.isPresentIn(grammar) ||
        GrammarToken.nounSingular.isPresentIn(grammar) ||
        GrammarToken.nounPlural.isPresentIn(grammar)) {
      final head = words.last;

      // A. Strict POS Check on Head Noun
      if (!analyzer.isNoun(head)) {
        // Allow fallback if word is unknown, but flag if it's definitely a verb
        if (analyzer.isVerb(head)) {
          return GrammarResult.invalid(
            reason: 'The subject "$head" seems to be a Verb (Action).',
            correction: 'Ensure the name describes a specific Object.',
          );
        }
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

      // C. Modifier Check (No Verbs/Gerunds allowed in Noun Phrases)
      // e.g. "LoadingState" is okay for State, but "LoadingUser" is weird for Entity.
      for (var i = 0; i < words.length - 1; i++) {
        final word = words[i];
        if (analyzer.isVerbGerund(word)) {
          return GrammarResult.invalid(
            reason: '"$word" is a Gerund (action), but this component should be a static Noun.',
            correction: 'Remove "$word" or change it to a descriptive adjective.',
          );
        }
        // Don't ban verbs entirely in modifiers (e.g. "RunLog"), but warn if pure action.
      }
      return const GrammarResult.valid();
    }

    // --- CASE 3: State (Adjective/Past/Gerund: "Loading", "Loaded", "Active") ---
    if (GrammarToken.adjective.isPresentIn(grammar) ||
        GrammarToken.verbGerund.isPresentIn(grammar) ||
        GrammarToken.verbPast.isPresentIn(grammar)) {
      final last = words.last;
      var match = false;

      if (GrammarToken.adjective.isPresentIn(grammar) && analyzer.isAdjective(last)) match = true;
      if (GrammarToken.verbGerund.isPresentIn(grammar) && analyzer.isVerbGerund(last)) match = true;
      if (GrammarToken.verbPast.isPresentIn(grammar) && analyzer.isVerbPast(last)) match = true;

      if (!match) {
        return GrammarResult.invalid(
          reason: 'The suffix "$last" does not describe a valid State.',
          correction: 'States should end with an Adjective, Past Action, or Ongoing Action.',
        );
      }
      return const GrammarResult.valid();
    }

    return const GrammarResult.valid();
  }

  /// Extracts the dynamic part of the name by stripping static grammar patterns.
  String _extractCoreName(String grammar, String className) {
    // Convert grammar "${noun}Repository" to Regex "(.*)Repository"
    var regexStr = RegExp.escape(grammar);

    // Replace all known tokens with capturing group
    for (final token in GrammarToken.values) {
      // Use the raw template string (e.g. ${noun})
      final escapedTemplate = RegExp.escape(token.template);
      regexStr = regexStr.replaceAll(escapedTemplate, '(.*)');
    }

    final regex = RegExp('^$regexStr\$');
    final match = regex.firstMatch(className);

    if (match != null) {
      // Combine all captured groups to form the core name
      // e.g. "I${noun}" matching "IUser" -> Group 1 is "User"
      final buffer = StringBuffer();
      for (var i = 1; i <= match.groupCount; i++) {
        buffer.write(match.group(i) ?? '');
      }
      return buffer.toString();
    }

    // If no match (or no tokens), return original class name
    return className;
  }
}

class GrammarResult {
  final bool isValid;
  final String? reason;
  final String? correction;

  const GrammarResult.valid() : isValid = true, reason = null, correction = null;

  const GrammarResult.invalid({required this.reason, required this.correction}) : isValid = false;
}
