import 'package:architecture_lints/src/engines/language/language_analyzer.dart';
import 'package:architecture_lints/src/schema/definitions/vocabulary_definition.dart';
import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/dictionary_msa.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// 1. Create a Mock for the Dictionary
class MockDictionary extends Mock implements DictionaryMSA {}

void main() {
  group('LanguageAnalyzer', () {
    late MockDictionary mockDict;

    // Helper to simulate a dictionary result
    void mockWord(String word, List<POS> posList) {
      when(() => mockDict.hasEntry(word.toLowerCase())).thenReturn(true);

      // Create a dummy entry with the requested POS tags
      final meanings = posList.map((p) =>
          DictEntryMeaning(p, 'description', [], [])
      ).toList();

      final entry = DictEntry(word, meanings, [], []);
      when(() => mockDict.getEntry(word.toLowerCase())).thenReturn(entry);
    }

    // Helper for "Word not found"
    void mockUnknown(String word) {
      when(() => mockDict.hasEntry(word.toLowerCase())).thenReturn(false);
    }

    setUp(() {
      mockDict = MockDictionary();
    });

    test('should identify basic Parts of Speech via Dictionary', () {
      final analyzer = LanguageAnalyzer(dictionary: mockDict);

      mockWord('User', [POS.NOUN]);
      mockWord('Get', [POS.VERB]);
      mockWord('Beautiful', [POS.ADJ]);

      expect(analyzer.isNoun('User'), isTrue);
      expect(analyzer.isVerb('Get'), isTrue);
      expect(analyzer.isAdjective('Beautiful'), isTrue);

      // Verify cross-checks fail
      expect(analyzer.isVerb('User'), isFalse);
    });

    test('should prioritize Vocabulary Definition overrides', () {
      // "Parsing" is technically a verb (gerund), but we define it as a Noun here.
      const vocabulary = VocabularyDefinition(
        nouns: {'parsing'},
        verbs: {'user'}, // Nonsense override to prove priority
      );

      final analyzer = LanguageAnalyzer(
        dictionary: mockDict,
        vocabulary: vocabulary,
      );

      // Even if dictionary says otherwise (or is empty), overrides win
      expect(analyzer.isNoun('Parsing'), isTrue);
      expect(analyzer.isVerb('User'), isTrue);
    });

    group('Plural Nouns', () {
      late LanguageAnalyzer analyzer;

      setUp(() {
        analyzer = LanguageAnalyzer(dictionary: mockDict);
      });

      test('should detect simple plurals ending in "s"', () {
        // "Users" -> stems to "User"
        mockWord('User', [POS.NOUN]);

        expect(analyzer.isNounPlural('Users'), isTrue);
        expect(analyzer.isNoun('Users'), isTrue); // Plurals are also Nouns
      });

      test('should detect plurals ending in "es"', () {
        // "Boxes" -> stems to "Box"
        mockWord('Box', [POS.NOUN]);

        expect(analyzer.isNounPlural('Boxes'), isTrue);
      });

      test('should detect plurals ending in "ies"', () {
        // "Entities" -> stems to "Entity"
        mockWord('Entity', [POS.NOUN]);

        expect(analyzer.isNounPlural('Entities'), isTrue);
      });

      test('should detect singular vs plural', () {
        mockWord('User', [POS.NOUN]);

        expect(analyzer.isNounSingular('User'), isTrue);
        expect(analyzer.isNounPlural('User'), isFalse);
      });
    });

    group('Verbs & Gerunds', () {
      late LanguageAnalyzer analyzer;

      setUp(() {
        analyzer = LanguageAnalyzer(dictionary: mockDict);
      });

      test('should detect Gerunds ending in "ing"', () {
        // "Loading" -> stems to "Load"
        mockWord('Load', [POS.VERB]);

        expect(analyzer.isVerbGerund('Loading'), isTrue);
      });

      test('should detect Past Tense ending in "ed"', () {
        // "Loaded" -> stems to "Load"
        mockWord('Load', [POS.VERB]);

        expect(analyzer.isVerbPast('Loaded'), isTrue);
      });

      test('should handle "e" suffix restoration (Save -> Saving)', () {
        // "Saving" -> stems to "Sav" (no) -> "Save" (yes)
        mockUnknown('Sav');
        mockWord('Save', [POS.VERB]);

        expect(analyzer.isVerbGerund('Saving'), isTrue);
      });
    });

    test('should fallback to Noun if treatEntryAsNounIfExists is true', () {
      // Scenario: Dictionary has the word, but it's listed as something obscure
      // or we just want to be lenient.
      final analyzer = LanguageAnalyzer(
        dictionary: mockDict,
        treatEntryAsNounIfExists: true,
      );

      mockWord('UnknownThing', [POS.ADV]); // Only listed as Adverb

      // Should return true because it exists in dictionary, even if not explicitly NOUN
      expect(analyzer.isNoun('UnknownThing'), isTrue);
    });

    test('should return false for unknown words', () {
      final analyzer = LanguageAnalyzer(dictionary: mockDict);
      mockUnknown('BlahBlah');

      expect(analyzer.isNoun('BlahBlah'), isFalse);
      expect(analyzer.isVerb('BlahBlah'), isFalse);
    });
  });
}
