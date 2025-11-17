// test/src/utils/natural_language_utils_test.dart

import 'package:clean_architecture_lints/src/utils/natural_language_utils.dart';
import 'package:test/test.dart';

void main() {
  group('NaturalLanguageUtils', () {
    late NaturalLanguageUtils nlpUtils;

    setUpAll(() {
      // Use overrides to make tests fast and deterministic, independent of the
      // actual dictionary content.
      final posOverrides = <String, Set<String>>{
        'get': {'VERB'}, 'save': {'VERB'}, 'delete': {'VERB'}, 'update': {'VERB'},
        'send': {'VERB'}, 'request': {'VERB'}, 'build': {'VERB'}, 'nest': {'VERB'},
        'user': {'NOUN'}, 'profile': {'NOUN'}, 'email': {'NOUN'}, 'morning': {'NOUN'},
        'successful': {'ADJ'}, 'empty': {'ADJ'}, 'invalid': {'ADJ'}, 'red': {'ADJ'},
        'sent': {'VERB'}, 'found': {'VERB'}, 'built': {'VERB'},
        // Ambiguous words for testing precedence
        'building': {'NOUN'},
        'nested': {'ADJ'},
      };
      nlpUtils = NaturalLanguageUtils(dictionary: null, posOverrides: posOverrides);
    });

    setUp(() {
      // Clear the cache before each test to ensure isolation.
      nlpUtils.clearCache();
    });

    group('Part of Speech checks', () {
      test('should correctly identify verbs from overrides', () {
        expect(nlpUtils.isVerb('Get'), isTrue);
        expect(nlpUtils.isVerb('Save'), isTrue);
      });

      test('should correctly identify nouns from overrides', () {
        expect(nlpUtils.isNoun('User'), isTrue);
        expect(nlpUtils.isNoun('Email'), isTrue);
      });

      test('should correctly identify adjectives from overrides', () {
        expect(nlpUtils.isAdjective('Successful'), isTrue);
        expect(nlpUtils.isAdjective('Red'), isTrue);
      });

      test('should return false for words not in overrides when dictionary is null', () {
        expect(nlpUtils.isVerb('NonExistentVerb'), isFalse);
        expect(nlpUtils.isNoun('NonExistentNoun'), isFalse);
      });
    });

    group('isVerbGerund', () {
      test('should return true for -ing forms of known verbs', () {
        expect(nlpUtils.isVerbGerund('Updating'), isTrue); // update -> updating
        expect(nlpUtils.isVerbGerund('Saving'), isTrue);   // save -> saving
      });

      test('should return false for words that are primarily nouns ending in -ing', () {
        // Our overrides define 'building' as a noun, so the heuristic should reject it.
        expect(nlpUtils.isVerbGerund('Building'), isFalse);
        expect(nlpUtils.isVerbGerund('Morning'), isFalse);
      });
    });

    group('isVerbPast', () {
      test('should return true for regular -ed verbs', () {
        expect(nlpUtils.isVerbPast('Requested'), isTrue);
      });

      test('should return true for common irregular verbs', () {
        expect(nlpUtils.isVerbPast('Sent'), isTrue);
        expect(nlpUtils.isVerbPast('Built'), isTrue);
      });

      test('should return false for words that are primarily adjectives ending in -ed', () {
        // Our overrides define 'nested' as an adjective, so the heuristic should reject it.
        expect(nlpUtils.isVerbPast('Nested'), isFalse);
        expect(nlpUtils.isVerbPast('Red'), isFalse);
      });
    });

    group('Caching Behavior', () {
      test('should use the cache for repeated lookups', () {
        expect(nlpUtils.cacheSize, 0);

        // First call populates the cache
        final result1 = nlpUtils.isNoun('User');
        expect(result1, isTrue);
        expect(nlpUtils.cacheSize, greaterThan(0));

        final cacheSizeAfterFirstCall = nlpUtils.cacheSize;

        // Second call should hit the cache
        final result2 = nlpUtils.isNoun('User');
        expect(result2, isTrue);
        // The cache size should NOT have increased.
        expect(nlpUtils.cacheSize, cacheSizeAfterFirstCall);
      });
    });
  });
}