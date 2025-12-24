import 'package:architecture_lints/src/engines/language/language_analyzer.dart';
import 'package:architecture_lints/src/lints/naming/logic/grammar_logic.dart';
import 'package:architecture_lints/src/utils/architecture_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class GrammarTester with GrammarLogic {}

class MockLanguageAnalyzer extends Mock implements LanguageAnalyzer {}

void main() {
  group('GrammarLogic', () {
    late GrammarTester tester;
    late MockLanguageAnalyzer mockAnalyzer;

    setUpAll(() {
      ArchLogger.configure(enabled: true);
      ArchLogger.includeTags(['GrammarLogic']);
    });

    setUp(() {
      tester = GrammarTester();
      mockAnalyzer = MockLanguageAnalyzer();

      // Default mocks to false
      when(() => mockAnalyzer.isNoun(any())).thenReturn(false);
      when(() => mockAnalyzer.isNounPlural(any())).thenReturn(false);
      when(() => mockAnalyzer.isNounSingular(any())).thenReturn(false);
      when(() => mockAnalyzer.isVerb(any())).thenReturn(false);
      when(() => mockAnalyzer.isVerbGerund(any())).thenReturn(false);
      when(() => mockAnalyzer.isVerbPast(any())).thenReturn(false);
      when(() => mockAnalyzer.isAdjective(any())).thenReturn(false);
    });

    void mockNoun(String word) => when(() => mockAnalyzer.isNoun(word)).thenReturn(true);
    void mockVerb(String word) => when(() => mockAnalyzer.isVerb(word)).thenReturn(true);
    void mockGerund(String word) => when(() => mockAnalyzer.isVerbGerund(word)).thenReturn(true);
    void mockAdj(String word) => when(() => mockAnalyzer.isAdjective(word)).thenReturn(true);

    group('Core Name Extraction', () {
      test('should extract core name from {{noun}}Repository', () {
        mockNoun('User');
        const grammar = '{{noun}}Repository';

        final result = tester.validateGrammar(grammar, 'UserRepository', mockAnalyzer);
        expect(result.isValid, isTrue);

        verify(() => mockAnalyzer.isNoun('User')).called(1);
      });

      test('should fallback to full name if extraction fails', () {
        // Class 'UserHelper' does not end with 'Repository'.
        // Logic falls back to analyzing 'UserHelper'.
        // 'UserHelper' splits into ['User', 'Helper'].
        // We validate 'Helper' is a noun.

        mockNoun('Helper');
        // 'User' is a modifier, defaults to valid (not gerund)

        const grammar = '{{noun}}Repository';

        final result = tester.validateGrammar(grammar, 'UserHelper', mockAnalyzer);
        expect(result.isValid, isTrue);

        // Verify we analyzed the head word
        verify(() => mockAnalyzer.isNoun('Helper')).called(1);
      });
    });

    group('Noun Phrases', () {
      const grammar = '{{noun.phrase}}';

      test('should detect Gerund violation (ParsingUser)', () {
        mockGerund('Parsing');
        mockNoun('User');

        final result = tester.validateGrammar(grammar, 'ParsingUser', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('is a Gerund'));
      });

      test('should allow Adjectives (ActiveUser)', () {
        mockAdj('Active');
        when(() => mockAnalyzer.isVerbGerund('Active')).thenReturn(false);
        mockNoun('User');

        final result = tester.validateGrammar(grammar, 'ActiveUser', mockAnalyzer);

        expect(result.isValid, isTrue);
      });
    });

    group('Actions', () {
      const grammar = '{{verb}}{{noun}}';

      test('should pass valid action', () {
        mockVerb('Get');
        mockNoun('User');
        expect(tester.validateGrammar(grammar, 'GetUser', mockAnalyzer).isValid, isTrue);
      });

      test('should fail if first word is not verb', () {
        mockNoun('User');
        mockNoun('Data');

        final result = tester.validateGrammar(grammar, 'UserData', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('not a recognized Verb'));
      });
    });

    group('States', () {
      const grammar = '{{noun}}{{adjective}}';

      test('should fail if suffix is not Adjective', () {
        mockNoun('User');
        mockNoun('Data'); // Not Adjective

        final result = tester.validateGrammar(grammar, 'UserData', mockAnalyzer);

        expect(result.isValid, isFalse);
        expect(result.reason, contains('does not describe a valid State'));
      });
    });
  });
}
