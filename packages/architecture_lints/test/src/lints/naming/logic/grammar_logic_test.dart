import 'package:architecture_lints/src/engines/language/language_analyzer.dart';
import 'package:architecture_lints/src/lints/naming/logic/grammar_logic.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Concrete class to test the Mixin
class GrammarTester with GrammarLogic {}

class MockLanguageAnalyzer extends Mock implements LanguageAnalyzer {}

void main() {
  group('GrammarLogic', () {
    late GrammarTester tester;
    late MockLanguageAnalyzer mockAnalyzer;

    setUp(() {
      tester = GrammarTester();
      mockAnalyzer = MockLanguageAnalyzer();

      // FIX: Default all boolean checks to false for ANY word.
      // This prevents "Null is not subtype of bool" crashes for unstubbed words.
      when(() => mockAnalyzer.isNoun(any())).thenReturn(false);
      when(() => mockAnalyzer.isNounPlural(any())).thenReturn(false);
      when(() => mockAnalyzer.isNounSingular(any())).thenReturn(false);
      when(() => mockAnalyzer.isVerb(any())).thenReturn(false);
      when(() => mockAnalyzer.isVerbGerund(any())).thenReturn(false);
      when(() => mockAnalyzer.isVerbPast(any())).thenReturn(false);
      when(() => mockAnalyzer.isAdjective(any())).thenReturn(false);
    });

    // --- Helpers to override defaults for specific words ---

    void setupNoun(String word, {bool plural = false, bool singular = true}) {
      when(() => mockAnalyzer.isNoun(word)).thenReturn(true);
      when(() => mockAnalyzer.isNounPlural(word)).thenReturn(plural);
      when(() => mockAnalyzer.isNounSingular(word)).thenReturn(singular);
      // Explicitly ensure it's not a verb/adj for this specific word
      when(() => mockAnalyzer.isVerb(word)).thenReturn(false);
    }

    void setupVerb(String word, {bool gerund = false, bool past = false}) {
      when(() => mockAnalyzer.isVerb(word)).thenReturn(true);
      when(() => mockAnalyzer.isVerbGerund(word)).thenReturn(gerund);
      when(() => mockAnalyzer.isVerbPast(word)).thenReturn(past);
      // Explicitly ensure it's not a noun
      when(() => mockAnalyzer.isNoun(word)).thenReturn(false);
    }

    void setupAdjective(String word) {
      when(() => mockAnalyzer.isAdjective(word)).thenReturn(true);
      when(() => mockAnalyzer.isNoun(word)).thenReturn(false);
      when(() => mockAnalyzer.isVerb(word)).thenReturn(false);
    }

    // --- Tests ---

    group('Core Name Extraction', () {
      test('should extract core name from suffix template', () {
        setupNoun('User');
        const grammar = '{{noun}}Repository';

        final result = tester.validateGrammar(grammar, 'UserRepository', mockAnalyzer);
        expect(result.isValid, isTrue);

        verify(() => mockAnalyzer.isNoun('User')).called(1);
      });

      test('should extract core name from prefix template', () {
        setupNoun('User');
        const grammar = 'I{{noun}}';

        final result = tester.validateGrammar(grammar, 'IUser', mockAnalyzer);
        expect(result.isValid, isTrue);

        verify(() => mockAnalyzer.isNoun('User')).called(1);
      });

      test('should fallback to full name if extraction pattern fails', () {
        // Grammar expects "Repository" suffix. Class is "UserHelper".
        // Regex fails. Core name becomes "UserHelper".
        // Split: ["User", "Helper"]. Head: "Helper".

        setupNoun('Helper'); // Helper must be a noun for this to pass
        const grammar = '{{noun}}Repository';

        final result = tester.validateGrammar(grammar, 'UserHelper', mockAnalyzer);
        expect(result.isValid, isTrue);

        // It analyzed the head word of the full name
        verify(() => mockAnalyzer.isNoun('Helper')).called(1);
      });
    });

    group('Priority 1: Actions (Verb-Noun)', () {
      const grammar = '{{verb}}{{noun}}';

      test('should pass for valid Action+Subject', () {
        setupVerb('Get');
        setupNoun('User');

        final result = tester.validateGrammar(grammar, 'GetUser', mockAnalyzer);
        expect(result.isValid, isTrue);
      });

      test('should fail if name is too short (only 1 word)', () {
        setupVerb('Get');
        final result = tester.validateGrammar(grammar, 'Get', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('too short'));
      });

      test('should fail if first word is not a Verb', () {
        setupNoun('User');
        setupNoun('Data');

        final result = tester.validateGrammar(grammar, 'UserData', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('not a recognized Verb'));
      });

      test('should fail if last word is not a Noun', () {
        setupVerb('Start');
        setupVerb('Running');

        final result = tester.validateGrammar(grammar, 'StartRunning', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('not a recognized Noun'));
      });
    });

    group('Priority 2: States (Adjective/Past/Gerund)', () {
      test('should pass for Noun + Adjective ({{adjective}})', () {
        const grammar = '{{noun}}{{adjective}}';
        setupNoun('User');
        setupAdjective('Active');

        final result = tester.validateGrammar(grammar, 'UserActive', mockAnalyzer);
        expect(result.isValid, isTrue);
      });

      test('should pass for Noun + Past Verb ({{verb.past}})', () {
        const grammar = '{{noun}}{{verb.past}}';
        setupNoun('User');
        setupVerb('Loaded', past: true);

        final result = tester.validateGrammar(grammar, 'UserLoaded', mockAnalyzer);
        expect(result.isValid, isTrue);
      });

      test('should fail if suffix is not a valid State', () {
        const grammar = '{{noun}}{{adjective}}';
        setupNoun('User');
        setupNoun('Data'); // Not an adjective

        final result = tester.validateGrammar(grammar, 'UserData', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('does not describe a valid State'));
      });
    });

    group('Priority 3: Objects (Noun Phrases)', () {
      const grammar = '{{noun.phrase}}';

      test('should pass for simple Noun', () {
        setupNoun('User');
        final result = tester.validateGrammar(grammar, 'User', mockAnalyzer);
        expect(result.isValid, isTrue);
      });

      test('should fail if Head (Subject) is a Verb', () {
        setupVerb('Login');

        final result = tester.validateGrammar(grammar, 'Login', mockAnalyzer);
        expect(result.isValid, isFalse);
        expect(result.reason, contains('seems to be a Verb'));
      });

      test('should enforce Plurality ({{noun.plural}})', () {
        const grammarPlural = '{{noun.plural}}';

        setupNoun('Users', plural: true, singular: false);
        expect(tester.validateGrammar(grammarPlural, 'Users', mockAnalyzer).isValid, isTrue);

        setupNoun('User', plural: false, singular: true);
        final result = tester.validateGrammar(grammarPlural, 'User', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('not a Plural Noun'));
      });

      test('should forbid Gerund modifiers in Noun Phrases', () {
        // "ParsingUser" -> "Parsing" is gerund modifier
        setupVerb('Parsing', gerund: true);
        setupNoun('User');

        final result = tester.validateGrammar(grammar, 'ParsingUser', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('is a Gerund'));
      });

      test('should allow Adjective modifiers', () {
        // "ActiveUser" -> "Active" is adjective
        setupAdjective('Active');
        setupNoun('User');

        // This used to crash because isVerbGerund('Active') returned null.
        // Now it returns false (default).
        final result = tester.validateGrammar(grammar, 'ActiveUser', mockAnalyzer);
        expect(result.isValid, isTrue);
      });
    });
  });
}
