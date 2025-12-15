import 'package:architecture_lints/src/lints/naming/logic/grammar_logic.dart';
import 'package:architecture_lints/src/utils/nlp/language_analyzer.dart';
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
    });

    void setupNoun(String word, {bool plural = false, bool singular = true}) {
      when(() => mockAnalyzer.isNoun(word)).thenReturn(true);
      when(() => mockAnalyzer.isVerb(word)).thenReturn(false);
      when(() => mockAnalyzer.isNounPlural(word)).thenReturn(plural);
      when(() => mockAnalyzer.isNounSingular(word)).thenReturn(singular);
      // Default others to false
      when(() => mockAnalyzer.isVerbGerund(word)).thenReturn(false);
      when(() => mockAnalyzer.isAdjective(word)).thenReturn(false);
    }

    void setupVerb(String word, {bool gerund = false, bool past = false}) {
      when(() => mockAnalyzer.isVerb(word)).thenReturn(true);
      when(() => mockAnalyzer.isNoun(word)).thenReturn(false);
      when(() => mockAnalyzer.isVerbGerund(word)).thenReturn(gerund);
      when(() => mockAnalyzer.isVerbPast(word)).thenReturn(past);
    }

    void setupAdjective(String word) {
      when(() => mockAnalyzer.isAdjective(word)).thenReturn(true);
      when(() => mockAnalyzer.isVerb(word)).thenReturn(false);
      when(() => mockAnalyzer.isNoun(word)).thenReturn(false);
    }

    group('Core Name Extraction', () {
      test('should extract core name from grammar template', () {
        // We test via validateGrammar, which calls _extractCoreName internally.
        // We set up "User" as a valid noun so validation passes if extraction works.
        setupNoun('User');

        const grammar = r'${noun}Repository'; // e.g. UserRepository
        const className = 'UserRepository';

        final result = tester.validateGrammar(grammar, className, mockAnalyzer);
        expect(result.isValid, isTrue);

        verify(() => mockAnalyzer.isNoun('User')).called(1);
      });

      test('should handle prefix templates', () {
        setupNoun('User');
        const grammar = r'I${noun}'; // e.g. IUser

        final result = tester.validateGrammar(grammar, 'IUser', mockAnalyzer);
        expect(result.isValid, isTrue);
      });
    });

    group('Case 1: Verb-Noun (UseCase)', () {
      const grammar = r'${verb}${noun}'; // e.g. GetUser

      test('should pass for valid Verb+Noun', () {
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
        setupNoun('User'); // "User" is noun, not verb
        setupNoun('Data');

        final result = tester.validateGrammar(grammar, 'UserData', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('not a recognized Verb'));
      });

      test('should fail if last word is not a Noun', () {
        setupVerb('Get');
        setupVerb('Started'); // "Started" is verb, not noun

        final result = tester.validateGrammar(grammar, 'GetStarted', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('not a recognized Noun'));
      });
    });

    group('Case 2: Noun Phrase (Entity/Model)', () {
      const grammar = r'${noun}';

      test('should pass for simple Noun', () {
        setupNoun('User');
        final result = tester.validateGrammar(grammar, 'User', mockAnalyzer);
        expect(result.isValid, isTrue);
      });

      test('should fail if Subject is a Verb', () {
        setupVerb('Login'); // "Login" treated as action here

        final result = tester.validateGrammar(grammar, 'Login', mockAnalyzer);
        expect(result.isValid, isFalse);
        expect(result.reason, contains('seems to be a Verb'));
      });

      test('should enforce Plurality', () {
        const grammarPlural = r'${noun.plural}';

        setupNoun('Users', plural: true, singular: false);
        expect(tester.validateGrammar(grammarPlural, 'Users', mockAnalyzer).isValid, isTrue);

        setupNoun('User', plural: false, singular: true);
        final result = tester.validateGrammar(grammarPlural, 'User', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('not a Plural Noun'));
      });

      test('should forbid Gerund modifiers', () {
        // "LoadingUser" -> "Loading" is gerund
        setupVerb('Loading', gerund: true);
        setupNoun('User');

        final result = tester.validateGrammar(grammar, 'LoadingUser', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('is a Gerund'));
      });
    });

    group('Case 3: State (Adjective/Past/Gerund)', () {
      const grammar = r'${noun}${adjective}'; // e.g. UserActive

      test('should pass for Noun + Adjective', () {
        setupNoun('User');
        setupAdjective('Active');

        final result = tester.validateGrammar(grammar, 'UserActive', mockAnalyzer);
        expect(result.isValid, isTrue);
      });

      test('should fail if suffix is not Adjective (when required)', () {
        setupNoun('User');
        setupNoun('Data'); // Data is noun, not adjective

        final result = tester.validateGrammar(grammar, 'UserData', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('does not describe a valid State'));
      });

      test('should pass for Verb Gerund if allowed', () {
        const grammarGerund = r'${noun}${verb.gerund}'; // e.g. AuthLoading
        setupNoun('Auth');
        setupVerb('Loading', gerund: true);

        final result = tester.validateGrammar(grammarGerund, 'AuthLoading', mockAnalyzer);
        expect(result.isValid, isTrue);
      });
    });
  });
}
