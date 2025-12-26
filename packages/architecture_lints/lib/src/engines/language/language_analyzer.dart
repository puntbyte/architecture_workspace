import 'package:architecture_lints/src/engines/language/nlp_constants.dart';
import 'package:architecture_lints/src/schema/definitions/vocabulary_definition.dart';
import 'package:lexicor/lexicor.dart';

class LanguageAnalyzer {
  static Lexicor? _sharedLexicor;
  static bool _initTried = false;

  final Lexicor? _lexicor;
  final VocabularyDefinition _overrides;
  final bool treatEntryAsNounIfExists;

  LanguageAnalyzer({
    Lexicor? lexicor,
    VocabularyDefinition? vocabulary,
    this.treatEntryAsNounIfExists = true,
  }) : _lexicor = lexicor ?? _sharedLexicor,
       _overrides = vocabulary ?? const VocabularyDefinition();

  static Future<void> initShared() async {
    if (_initTried) return;
    _initTried = true;

    if (_sharedLexicor == null) {
      try {
        _sharedLexicor = await Lexicor.init(mode: StorageMode.onDisk);
      } catch (e) {
        // print('[LanguageAnalyzer] Lexicor init failed: $e');
      }
    }
  }

  bool isAdjective(String word) => _hasPos(word, SpeechPart.adjective);

  bool isAdverb(String word) {
    final lower = word.toLowerCase();
    if (_hasPos(lower, SpeechPart.adverb)) return true;
    if (lower.endsWith('ly') && !commonNouns.contains(lower)) return true;
    return commonAdverbs.contains(lower);
  }

  bool isNoun(String word) {
    if (_hasPos(word, SpeechPart.noun)) return true;
    // Check if it's a plural form of a known noun
    return isNounPlural(word);
  }

  bool isNounPlural(String word) {
    final lower = word.toLowerCase();
    if (_overrides.nouns.contains(lower)) return true;

    // 1. Basic Suffix Check
    if (!lower.endsWith('s')) return false;

    // 2. Irregular check
    if (singularNounExceptions.contains(lower)) return false;
    if (irregularPlurals.containsKey(lower)) return true;

    // 3. Morphology Check (Strip Suffixes)
    // Try "users" -> "user"
    if (_hasPos(lower.substring(0, lower.length - 1), SpeechPart.noun)) return true;

    // Try "boxes" -> "box"
    if (lower.endsWith('es')) {
      if (_hasPos(lower.substring(0, lower.length - 2), SpeechPart.noun)) return true;
    }

    // Try "entities" -> "entity"
    if (lower.endsWith('ies')) {
      final stem = lower.substring(0, lower.length - 3);
      if (_hasPos('${stem}y', SpeechPart.noun)) return true;
    }

    return false;
  }

  bool isNounSingular(String word) => isNoun(word) && !isNounPlural(word);

  /// Heuristically checks if a sequence of [words] forms a Noun Phrase.
  /// Simple: Last word is a noun, previous words are adjectives/nouns.
  bool isNounPhrase(List<String> words) {
    if (words.isEmpty) return false;
    final lastWord = words.last;
    if (!isNoun(lastWord)) return false; // Must end in a noun

    // All preceding words should be adjectives or nouns acting as modifiers
    for (var i = 0; i < words.length - 1; i++) {
      final word = words[i];
      if (!isAdjective(word) && !isNoun(word)) {
        return false; // Not a valid modifier
      }
    }
    return true;
  }

  bool isNounSingularPhrase(List<String> words) =>
      isNounPhrase(words) && isNounSingular(words.last);

  bool isNounPluralPhrase(List<String> words) => isNounPhrase(words) && isNounPlural(words.last);

  bool isVerb(String word) => _hasPos(word, SpeechPart.verb);

  /// Checks if a sequence of words forms a Verb Phrase.
  /// Structure: [Verb] + [Adverb | Preposition | Noun (as particle)]
  /// e.g. "Log In" (Verb + Prep), "Sign Up" (Verb + Adv), "Run Fast" (Verb + Adv)
  bool isVerbPhrase(List<String> words) {
    if (words.isEmpty) return false;

    // 1. Must start with a Verb
    if (!isVerb(words.first)) return false;

    // 2. Subsequent words must be modifiers or particles
    for (var i = 1; i < words.length; i++) {
      final word = words[i];
      // Allow Adverbs, Prepositions, or even Nouns acting as particles (e.g. "Back")
      // We are lenient here to support phrasal verbs.
      if (!isAdverb(word) && !isPreposition(word) && !isNoun(word)) {
        return false;
      }
    }
    return true;
  }

  bool isVerbGerund(String word) {
    final lower = word.toLowerCase();

    // Override check
    if (_overrides.nouns.contains(lower)) return false;
    if (_overrides.verbs.contains(lower)) return true;

    if (!lower.endsWith('ing')) return false;

    // 1. Direct Lookup (e.g. "Running" might find "Run")
    // Note: As seen in demo, "fetching" might resolve to AdjectiveSatellite,
    // so we can't rely solely on _hasPos(verb) for the gerund form itself.

    // 2. Stem Check (Manual)
    // "fetching" -> "fetch"
    final stem = lower.substring(0, lower.length - 3);
    if (isVerb(stem)) return true;

    // "saving" -> "save"
    if (isVerb('${stem}e')) return true;

    // "running" -> "run" (Double consonant)
    // If stem ends in double char (e.g. runn), try stripping one.
    if (stem.length > 1 && stem[stem.length - 1] == stem[stem.length - 2]) {
      if (isVerb(stem.substring(0, stem.length - 1))) return true;
    }

    return false;
  }

  bool isVerbPast(String word) {
    final lower = word.toLowerCase();
    if (_overrides.verbs.contains(lower)) return true;
    if (irregularPastVerbs.containsKey(lower)) return true;

    if (lower.endsWith('ed')) {
      final stem = lower.substring(0, lower.length - 2);
      if (isVerb(stem)) return true;
      if (isVerb('${stem}e')) return true;

      // "stopped" -> "stop"
      if (stem.length > 1 && stem[stem.length - 1] == stem[stem.length - 2]) {
        if (isVerb(stem.substring(0, stem.length - 1))) return true;
      }
    }

    return isVerb(word); // Fallback if irregular is just a verb form in DB
  }

  /// Heuristically checks if a sequence of [words] forms a Verb Phrase (Present Tense).
  /// Simple: First word is a verb, subsequent are adverbs.
  bool isVerbPresentPhrase(List<String> words) {
    if (words.isEmpty) return false;
    final firstWord = words.first;
    if (!isVerb(firstWord)) return false; // Must start with a verb (e.g., "Get")

    // Subsequent words should be adverbs (e.g., "quickly")
    for (var i = 1; i < words.length; i++) {
      final word = words[i];
      if (!isAdverb(word)) return false;
    }
    return true;
  }

  // Example, this can be expanded for Past Tense
  bool isVerbPastPhrase(List<String> words) {
    if (words.isEmpty) return false;
    final firstWord = words.first;
    if (!isVerbPast(firstWord)) return false; // Must start with a past verb (e.g., "Got")

    for (var i = 1; i < words.length; i++) {
      final word = words[i];
      if (!isAdverb(word)) return false;
    }
    return true;
  }

  bool isPreposition(String word) => commonPrepositions.contains(word.toLowerCase());

  bool isConjunction(String word) => commonConjunctions.contains(word.toLowerCase());

  bool _hasPos(String word, SpeechPart part) {
    final lower = word.toLowerCase();

    // 1. Vocabulary Overrides
    if (part == SpeechPart.noun && _overrides.nouns.contains(lower)) return true;
    if (part == SpeechPart.verb && _overrides.verbs.contains(lower)) return true;
    if (part == SpeechPart.adjective && _overrides.adjectives.contains(lower)) return true;

    // 2. Constants
    if (part == SpeechPart.noun && commonNouns.contains(lower)) return true;
    if (part == SpeechPart.verb && commonVerbs.contains(lower)) return true;
    if (part == SpeechPart.adverb && commonAdverbs.contains(lower)) return true;

    // 3. Lexicor
    if (_lexicor != null) {
      return _checkLexicor(lower, part);
    }

    // Fallback if DB missing: assume simple checks passed before calling _hasPos
    // (e.g. isVerbGerund check for 'ing') were not enough, so we assume valid if unknown?
    // Or assume invalid?
    // For a Linter, it is better to be lenient if DB is offline than to flag everything.
    // But here we return false (Not a Noun/Verb) if we can't prove it.
    return false;
  }

  bool _checkLexicor(String word, SpeechPart part) {
    try {
      final result = _lexicor!.lookup(word);
      if (result.concepts.isEmpty) return false;

      // Check if any concept matches the part
      if (result.concepts.any((c) => c.part == part)) return true;

      // Check resolved forms (Morphology)
      // e.g. "went" -> resolvedForms: ["went", "go"]
      // If "go" is a verb, then "went" is valid verb form.
      // (This is useful if lookup('went') returns concepts for 'go' but marks them as Verb)
      // Actually result.concepts ARE the concepts for the resolved form.

      // Weak signal fallback for Nouns
      if (treatEntryAsNounIfExists && part == SpeechPart.noun) return true;
    } catch (_) {}
    return false;
  }
}
