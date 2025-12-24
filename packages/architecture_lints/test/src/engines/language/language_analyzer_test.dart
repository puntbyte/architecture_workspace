import 'package:architecture_lints/src/engines/language/language_analyzer.dart';
import 'package:architecture_lints/src/schema/definitions/vocabulary_definition.dart';
import 'package:lexicor/lexicor.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Mocks
class MockLexicor extends Mock implements Lexicor {}

class MockLookupResult extends Mock implements LookupResult {}

class MockConcept extends Mock implements Concept {}

void main() {
  group('LanguageAnalyzer', () {
    late MockLexicor mockLexicor;
    late LanguageAnalyzer analyzer;

    setUp(() {
      mockLexicor = MockLexicor();
      // Inject the mock instance directly (bypassing initShared for unit test)
      analyzer = LanguageAnalyzer(lexicor: mockLexicor);
    });

    // Helper to simulate a Lexicor lookup result
    void mockWord(String word, List<SpeechPart> parts) {
      final concepts = parts.map((part) {
        final concept = MockConcept();
        when(() => concept.part).thenReturn(part);
        return concept;
      }).toList();

      final result = MockLookupResult();
      when(() => result.concepts).thenReturn(concepts);
      when(() => result.isEmpty).thenReturn(concepts.isEmpty);

      // Match case-insensitive lookup
      when(() => mockLexicor.lookup(word.toLowerCase())).thenReturn(result);
    }

    test('isNoun returns true for known nouns', () {
      mockWord('User', [SpeechPart.noun]);
      expect(analyzer.isNoun('User'), isTrue);
    });

    test('isVerb returns true for known verbs', () {
      mockWord('Get', [SpeechPart.verb]);
      expect(analyzer.isVerb('Get'), isTrue);
    });

    test('isAdjective returns true for known adjectives', () {
      mockWord('Beautiful', [SpeechPart.adjective]);
      expect(analyzer.isAdjective('Beautiful'), isTrue);
    });

    group('Plural Nouns', () {
      test('should detect plurals ending in "s"', () {
        // "Users" lookup returns Noun (stemming handled by Lexicor lookup logic in real usage,
        // but here we just mock that 'users' returns a noun concept).
        mockWord('Users', [SpeechPart.noun]);

        expect(analyzer.isNounPlural('Users'), isTrue);
      });

      test('should NOT detect as plural if word does not end in s', () {
        // Even if it's a noun, if it doesn't end in S, we assume singular
        // unless irregular list logic overrides (which is internal to analyzer).
        mockWord('User', [SpeechPart.noun]);

        expect(analyzer.isNounPlural('User'), isFalse);
      });
    });

    group('Verbs & Gerunds', () {
      test('should detect Gerunds (ending in ing)', () {
        // Parsing -> lookup('parsing') -> finds verb concept (e.g. parse)
        mockWord('Parsing', [SpeechPart.verb]);

        expect(analyzer.isVerbGerund('Parsing'), isTrue);
      });

      test('should fail Gerund check if not a verb', () {
        // "String" ends in ing, but is a Noun
        mockWord('String', [SpeechPart.noun]);

        expect(analyzer.isVerbGerund('String'), isFalse);
      });

      test('should detect Past Tense (ending in ed)', () {
        // Loaded -> lookup('loaded') -> finds verb concept (load)
        mockWord('Loaded', [SpeechPart.verb]);

        expect(analyzer.isVerbPast('Loaded'), isTrue);
      });
    });

    test('should return false for unknown words', () {
      mockWord('Blah', []); // No concepts found

      expect(analyzer.isNoun('Blah'), isFalse);
      expect(analyzer.isVerb('Blah'), isFalse);
    });

    test('should prioritize Vocabulary overrides', () {
      const vocab = VocabularyDefinition(
        nouns: {'parsing'}, // Override 'parsing' to be a noun
      );

      final analyzerWithOverride = LanguageAnalyzer(
        lexicor: mockLexicor,
        vocabulary: vocab,
      );

      // Even if dictionary says it's a verb (or nothing), override wins
      expect(analyzerWithOverride.isNoun('Parsing'), isTrue);
    });
  });
}
