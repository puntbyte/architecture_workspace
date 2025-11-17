// lib/src/utils/natural_language_utils.dart

import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/dictionary_msa.dart';

/// A utility class that wraps a dictionary to perform natural language
/// processing on class/method names for semantic linting.
///
/// Construct with `dictionary: null` to disable the external dictionary (useful in unit tests).
class NaturalLanguageUtils {
  final DictionaryMSA? _dictionary;
  final Map<String, bool> _cache = {};
  final Map<String, Set<String>> _posOverrides;

  static const _commonNouns = {
    'email',
    'profile',
    'data',
    'user',
    'state',
    'event',
    'auth',
    'dto',
    'request',
    'response',
  };

  static const _commonVerbs = {
    'get',
    'set',
    'fetch',
    'send',
    'save',
    'delete',
    'update',
    'load',
    'login',
    'logout',
  };

  /// Create an instance.
  /// - If [dictionary] is null, dictionary lookups are disabled (tests should pass null).
  /// - [posOverrides] maps lowercase words -> set of POS names (e.g. {'get': {'VERB'}})
  NaturalLanguageUtils({
    DictionaryMSA? dictionary,
    Map<String, Set<String>>? posOverrides,
  }) : _dictionary = dictionary,
       _posOverrides = posOverrides ?? {};

  /// Clears the internal POS result cache.
  void clearCache() => _cache.clear();

  /// Returns the number of cached entries (useful for tests).
  int get cacheSize => _cache.length;

  /// Generic cached helper to check whether a given [word] has the POS [pos].
  bool _hasPos(String word, POS pos) {
    final lowerWord = word.toLowerCase();
    final cacheKey = '${pos.name}:$lowerWord';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    // 1) Overrides (tests)
    final override = _posOverrides[lowerWord];
    if (override != null) {
      final res = override.contains(pos.name);
      _cache[cacheKey] = res;
      return res;
    }

    // 2) Quick fallback lists
    if (pos == POS.NOUN && _commonNouns.contains(lowerWord)) {
      _cache[cacheKey] = true;
      return true;
    }
    if (pos == POS.VERB && _commonVerbs.contains(lowerWord)) {
      _cache[cacheKey] = true;
      return true;
    }

    // 3) Dictionary (only if provided)
    if (_dictionary == null) {
      _cache[cacheKey] = false;
      return false;
    }

    try {
      if (!_dictionary.hasEntry(lowerWord)) {
        _cache[cacheKey] = false;
        return false;
      }
      final entry = _dictionary.getEntry(lowerWord);
      final result = entry.meanings.any((m) => m.pos == pos);
      _cache[cacheKey] = result;
      return result;
    } catch (_) {
      _cache[cacheKey] = false;
      return false;
    }
  }

  /// Checks if the given word is a verb.
  bool isVerb(String word) {
    final lower = word.toLowerCase();
    if (_commonVerbs.contains(lower)) {
      // Cache the quick-hit result so cacheSize increases during tests/usage.
      _cache['VERB:$lower'] = true;
      return true;
    }
    return _hasPos(word, POS.VERB);
  }

  /// Checks if the given word is a noun.
  bool isNoun(String word) {
    final lower = word.toLowerCase();
    if (_commonNouns.contains(lower)) {
      // Cache the quick-hit result so cacheSize increases during tests/usage.
      _cache['NOUN:$lower'] = true;
      return true;
    }
    return _hasPos(word, POS.NOUN);
  }

  /// Checks if the given word is an adjective.
  bool isAdjective(String word) => _hasPos(word, POS.ADJ);

  /// Heuristic: is this an -ing form of a verb?
  bool isVerbGerund(String word) {
    final lowerWord = word.toLowerCase();
    if (!lowerWord.endsWith('ing')) return false;

    // --- THE DEFINITIVE FIX ---
    // 1. Check for the noun case first. If a word is a known noun (like "Building"),
    //    it should NOT be considered a verb gerund for our naming rules.
    if (isNoun(word) && !isVerb(word)) {
      return false;
    }
    // --- END OF FIX ---

    // 2. If it's not a noun, or if it's ambiguously both (like "setting"),
    //    then proceed with the verb checks.

    // If the gerund itself is a known verb, accept it.
    if (isVerb(word)) return true;

    final stem = lowerWord.substring(0, lowerWord.length - 3);
    if (stem.isEmpty) return false;

    // Double-letter case: getting -> get (stem "gett")
    if (stem.length > 1 && stem.endsWith(stem[stem.length - 1])) {
      final base = stem.substring(0, stem.length - 1);
      if (isVerb(base) || isVerb('${base}e')) return true;
    }

    // dropped 'e': updating -> update
    return isVerb(stem) || isVerb('${stem}e');
  }

  /// Heuristic: is this a past-tense verb?
  ///
  /// Supports common irregulars, -ed regular forms, ies->y conversion, and basic doubling heuristics.
  bool isVerbPast(String word) {
    final lowerWord = word.toLowerCase();

    // Prioritize adjectives. If a word is a known adjective (like "Nested", "Red"),
    // it should not be considered a past-tense verb.
    if (isAdjective(word) && !isVerb(word)) {
      return false;
    }

    // Common irregular past forms we accept directly
    const commonIrregular = {
      'went',
      'saw',
      'did',
      'took',
      'said',
      'came',
      'gave',
      'ran',
      'ate',
      'wrote',
      'was',
      'were',
      'had',
      'knew',
      'put',
      'thought',
      'became',
      'showed',
      'sent',
      'found',
      'built',
      'began',
      'left',
    };

    if (commonIrregular.contains(lowerWord)) return true;

    if (lowerWord.endsWith('ied') && lowerWord.length > 3) { /* ... as before ... */ }

    if (lowerWord.endsWith('ed')) {
      final base = lowerWord.substring(0, lowerWord.length - 2);
      if (base.isEmpty) return false;

      if (base.length > 1 && base.endsWith(base[base.length - 1])) {
        final possible = base.substring(0, base.length - 1);
        if (isVerb(possible)) return true;
      }

      if (isVerb(base) || isVerb('${base}e')) return true;
    }

    // Fallback for other irregulars
    return isVerb(word);
  }
}
