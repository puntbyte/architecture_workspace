import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:architecture_lints/src/actions/architecture_fix.dart';
import 'package:architecture_lints/src/config/enums/variable_type.dart';
import 'package:architecture_lints/src/config/schema/action_config.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/template_definition.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/mocks.dart' hide resolveContent;
import '../../helpers/test_resolver.dart';

class TestArchitectureFix extends ArchitectureFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) => protectedRun(resolver, reporter, context, analysisError);
}

void main() {
  group('ArchitectureFix', () {
    late Directory tempDir;
    late MockChangeReporter mockReporter;
    late MockChangeBuilder mockBuilder;
    late FakeCustomLintContext fakeContext;
    late MockCustomLintResolver mockResolver;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fix_test_');
      mockReporter = MockChangeReporter();
      mockBuilder = MockChangeBuilder();
      fakeContext = FakeCustomLintContext();
      mockResolver = MockCustomLintResolver();

      when(
        () => mockReporter.createChangeBuilder(
          message: any(named: 'message'),
          priority: any(named: 'priority'),
        ),
      ).thenReturn(mockBuilder);

      when(
        () => mockBuilder.addDartFileEdit(any(), customPath: any(named: 'customPath')),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('should trigger file creation with correct content', () async {
      // 1. Setup Config
      const config = ArchitectureConfig(
        components: [],
        templates: {
          'simple_fix': TemplateDefinition(
            content: 'class {{name.pascalCase}}Fixed {}',
          ),
        },
        actions: [
          ActionConfig(
            id: 'fix_it',
            description: 'Fix It',
            trigger: ActionTrigger(errorCode: 'arch_error'),
            target: ActionTarget(directory: '.', filename: '{{name.pascalCase}}_fixed.dart'),
            templateId: 'simple_fix',
            variables: {
              'name': VariableConfig(
                type: VariableType.string,
                value: 'source.name',
              ),
            },
          ),
        ],
      );

      // 2. Resolve a real Dart file
      const sourceCode = 'class MyFeature {}';
      final unit = await resolveContent(sourceCode);

      // 3. Inject State
      fakeContext.sharedState[ArchitectureConfig] = config;
      fakeContext.sharedState[ResolvedUnitResult] = unit;

      when(() => mockResolver.path).thenReturn(unit.path);

      // 4. Mock the Analysis Error
      final error = MockDiagnostic();
      final errorCode = MockLintCode();

      // FIX: Use FakeDiagnosticMessage
      final diagnosticMessage = FakeDiagnosticMessage('Fix error');
      when(() => error.problemMessage).thenReturn(diagnosticMessage);

      when(() => errorCode.name).thenReturn('arch_error');
      when(() => error.diagnosticCode).thenReturn(errorCode);
      when(() => error.offset).thenReturn(sourceCode.indexOf('MyFeature'));
      when(() => error.length).thenReturn(9);

      // 5. Intercept Builder
      var editCallbackCaptured = false;
      final fakeBuilder = FakeDartFileEditBuilder();

      when(
        () => mockBuilder.addDartFileEdit(any(), customPath: any(named: 'customPath')),
      ).thenAnswer((invocation) {
        editCallbackCaptured = true;

        final customPath = invocation.namedArguments[#customPath] as String;
        const expectedFilename = 'MyFeature_fixed.dart';
        expect(customPath, endsWith(expectedFilename));

        final callback = invocation.positionalArguments[0] as void Function(DartFileEditBuilder);
        callback(fakeBuilder);
      });

      // 6. Run
      TestArchitectureFix().run(mockResolver, mockReporter, fakeContext, error, []);

      // 7. Verify
      verify(() => mockReporter.createChangeBuilder(message: 'Fix It', priority: 100)).called(1);

      expect(editCallbackCaptured, isTrue, reason: 'addDartFileEdit should be called');
      expect(fakeBuilder.output.toString(), contains('class MyFeatureFixed {}'));
    });
  });
}
