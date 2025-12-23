import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/lints/naming/rules/grammar_rule.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_resolver.dart';

class MockFileResolver extends Mock implements FileResolver {}

class TestGrammarRule extends GrammarRule {
  final ArchitectureConfig mockConfig;
  const TestGrammarRule(this.mockConfig);

  @override
  Future<void> startUp(CustomLintResolver resolver, CustomLintContext context) async {
    context.sharedState[ArchitectureConfig] = mockConfig;
    context.sharedState[FileResolver] = FileResolver(mockConfig);
    await super.startUp(resolver, context);
  }
}

void main() {
  group('GrammarRule Integration', () {
    late MockCustomLintResolver mockResolver;
    late MockDiagnosticReporter mockReporter;
    late FakeCustomLintContext fakeContext;
    late MockFileResolver mockFileResolver;

    setUpAll(() {
      registerFallbackValue(FakeToken());
      registerFallbackValue(FakeLintCode());
      registerFallbackValue(<Object>[]);
    });

    setUp(() {
      mockResolver = MockCustomLintResolver();
      mockReporter = MockDiagnosticReporter();
      fakeContext = FakeCustomLintContext();
      mockFileResolver = MockFileResolver();

      // Stub reporter
      when(() => mockReporter.atToken(
        any(),
        any(),
        arguments: any(named: 'arguments'),
        contextMessages: any(named: 'contextMessages'),
        data: any(named: 'data'),
      )).thenReturn(MockDiagnostic());
    });

    Future<void> runTest({
      required String yamlContent,
      required String dartContent,
    }) async {
      final result = await resolveContent(dartContent);

      final yamlMap = loadYaml(yamlContent);
      final configMap = Map<String, dynamic>.from(yamlMap as Map);
      final config = ArchitectureConfig.fromYaml(configMap);

      fakeContext.sharedState[ArchitectureConfig] = config;
      fakeContext.sharedState[FileResolver] = mockFileResolver;
      when(() => mockResolver.path).thenReturn(result.path);

      final rule = TestGrammarRule(config);
      final node = result.unit.declarations.first as ClassDeclaration;
      final componentDef = config.components.first;

      rule.checkName(
        node: node,
        config: componentDef,
        reporter: mockReporter,
        rootConfig: config,
      );
    }

    test('should report violation when Vocabulary defines "Parsing" as verb', () async {
      const yaml = '''
      vocabularies:
        verbs:
          - parsing
      
      components:
        .model:
          path: 'lib'
          grammar: ['{{noun.phrase}}Model']
          patterns: ['{{name}}Model']
      ''';

      const dart = 'class ParsingUserModel {}';

      await runTest(yamlContent: yaml, dartContent: dart);

      // CAPTURE verification to bypass strict type matching issues in 'verify'
      final captured = verify(() => mockReporter.atToken(
        captureAny(), // Capture Token
        captureAny(), // Capture LintCode
        arguments: captureAny(named: 'arguments'), // Capture Arguments List
      )).captured;

      expect(captured.length, 3, reason: 'Should capture Token, Code, and Arguments');

      // 1. Check Token
      final token = captured[0] as Token;
      expect(token.lexeme, 'ParsingUserModel');

      // 2. Check Error Code
      final code = captured[1] as LintCode;
      expect(code.name, 'arch_naming_grammar');

      // 3. Check Arguments
      final args = captured[2] as List<Object>;
      // Args: [Component Display Name, Failure Reason, Correction]
      // Display Name might be 'Model' (derived from .model id)

      expect(args.length, 3);
      final reason = args[1] as String;
      final correction = args[2] as String;

      expect(reason, contains('is a Gerund'), reason: 'Error reason should mention Gerund');
      expect(correction, contains('Remove "Parsing"'), reason: 'Correction should suggest removal');
    });
  });
}