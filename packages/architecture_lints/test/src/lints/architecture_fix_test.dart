import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:architecture_lints/src/engines/file/file.dart';

import 'package:architecture_lints/src/lints/architecture_fix.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/action_definition.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/schema/definitions/template_definition.dart';
import 'package:architecture_lints/src/schema/definitions/variable_definition.dart';
import 'package:architecture_lints/src/schema/descriptors/action_source.dart';
import 'package:architecture_lints/src/schema/descriptors/action_target.dart';
import 'package:architecture_lints/src/schema/descriptors/action_trigger.dart';
import 'package:architecture_lints/src/schema/descriptors/action_write.dart';
import 'package:architecture_lints/src/schema/enums/action_scope.dart';
import 'package:architecture_lints/src/schema/enums/variable_type.dart';
import 'package:architecture_lints/src/schema/enums/write_placement.dart';
import 'package:architecture_lints/src/schema/enums/write_strategy.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_resolver.dart';

class TestArchitectureFix extends ArchitectureFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    protectedRun(resolver, reporter, context, analysisError);
  }
}

void main() {
  group('ArchitectureFix', () {
    late MockChangeReporter mockReporter;
    late MockChangeBuilder mockBuilder;
    late FakeCustomLintContext fakeContext;
    late MockCustomLintResolver mockResolver;
    late TestProject project;

    setUp(() {
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
        () => mockBuilder.addDartFileEdit(
          any(),
          customPath: any(named: 'customPath'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      try {
        project.dispose();
      } catch (_) {}
    });

    test('should generate new file using current context variables', () async {
      // 1. Setup Config
      const config = ArchitectureConfig(
        components: [],
        templates: {
          'simple_fix': TemplateDefinition(
            // Accessing .pascalCase property on the 'name' map
            content: 'class {{name.pascalCase}}Fixed {}',
          ),
        },
        actions: [
          ActionDefinition(
            id: 'fix_it',
            description: 'Fix It',
            trigger: ActionTrigger(errorCode: 'arch_error'),
            source: ActionSource(scope: ActionScope.current),
            target: ActionTarget(scope: ActionScope.current),
            write: ActionWrite(
              strategy: WriteStrategy.file,
              // Interpolating filename also uses property access
              filename: '{{name.pascalCase}}_fixed.dart',
            ),
            templateId: 'simple_fix',
            variables: {
              'name': VariableDefinition(
                type: VariableType.string,
                // Expression evaluates to StringWrapper
                value: 'source.name',
              ),
            },
          ),
        ],
      );

      // 2. Setup Project
      project = await setupProject({
        'lib/feature/broken.dart': 'class broken_thing {}',
      });
      final unit = await project.resolve('lib/feature/broken.dart');

      // 3. Inject State
      fakeContext.sharedState[ArchitectureConfig] = config;
      fakeContext.sharedState[ResolvedUnitResult] = unit;
      fakeContext.sharedState[FileResolver] = FileResolver(config);

      when(() => mockResolver.path).thenReturn(unit.path);

      // 4. Mock Error
      final error = MockDiagnostic();
      final errorCode = MockLintCode();
      when(() => errorCode.name).thenReturn('arch_error');
      when(() => error.diagnosticCode).thenReturn(errorCode);
      // Offset points to 'broken_thing'
      when(() => error.offset).thenReturn(unit.content.indexOf('broken_thing'));
      when(() => error.length).thenReturn(12);

      // 5. Run
      final fix = TestArchitectureFix();

      final fakeEditBuilder = FakeDartFileEditBuilder();
      when(
        () => mockBuilder.addDartFileEdit(
          any(),
          customPath: any(named: 'customPath'),
        ),
      ).thenAnswer((invocation) {
        final callback = invocation.positionalArguments[0] as void Function(DartFileEditBuilder);
        callback(fakeEditBuilder);
      });

      await fix.protectedRun(mockResolver, mockReporter, fakeContext, error);

      // 6. Verify
      verify(() => mockReporter.createChangeBuilder(message: 'Fix It', priority: 100)).called(1);

      // 'broken_thing' -> PascalCase 'BrokenThing'
      final capturedPath =
          verify(
                () =>
                    mockBuilder.addDartFileEdit(any(), customPath: captureAny(named: 'customPath')),
              ).captured.first
              as String;
      expect(capturedPath, endsWith('BrokenThing_fixed.dart'));

      expect(fakeEditBuilder.output.toString(), contains('class BrokenThingFixed {}'));
    });

    test('should switch context to RELATED file and inject code', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentDefinition(id: 'domain.entity', paths: ['domain/entities']),
          ComponentDefinition(id: 'data.model', paths: ['data/models']),
        ],
        templates: {
          'mapper_method': TemplateDefinition(
            content: '{{entityName.value}} toEntity() => {{entityName.value}}();',
          ),
        },
        actions: [
          ActionDefinition(
            id: 'create_mapper',
            description: 'Create Mapper',
            trigger: ActionTrigger(errorCode: 'missing_mapper'),
            source: ActionSource(
              scope: ActionScope.related,
              component: 'domain.entity',
            ),
            target: ActionTarget(scope: ActionScope.current),
            write: ActionWrite(
              strategy: WriteStrategy.inject,
              placement: WritePlacement.end,
            ),
            templateId: 'mapper_method',
            variables: {
              'entityName': VariableDefinition(
                type: VariableType.string,
                value: 'source.name',
              ),
            },
          ),
        ],
      );

      project = await setupProject({
        'lib/domain/entities/user.dart': 'class User {}',
        'lib/data/models/user_model.dart': 'class UserModel {}',
      });

      final modelUnit = await project.resolve('lib/data/models/user_model.dart');

      fakeContext.sharedState[ArchitectureConfig] = config;
      fakeContext.sharedState[ResolvedUnitResult] = modelUnit;
      fakeContext.sharedState[FileResolver] = FileResolver(config);

      when(() => mockResolver.path).thenReturn(modelUnit.path);

      final error = MockDiagnostic();
      final errorCode = MockLintCode();
      when(() => errorCode.name).thenReturn('missing_mapper');
      when(() => error.diagnosticCode).thenReturn(errorCode);
      when(() => error.offset).thenReturn(modelUnit.content.indexOf('UserModel'));
      when(() => error.length).thenReturn(9);

      final fix = TestArchitectureFix();
      final fakeEditBuilder = FakeDartFileEditBuilder();

      when(
        () => mockBuilder.addDartFileEdit(
          any(),
          customPath: any(named: 'customPath'),
        ),
      ).thenAnswer((invocation) {
        final callback = invocation.positionalArguments[0] as void Function(DartFileEditBuilder);
        callback(fakeEditBuilder);
      });

      await fix.protectedRun(mockResolver, mockReporter, fakeContext, error);

      expect(
        fakeEditBuilder.output.toString(),
        contains('User toEntity() => User();'),
        reason: 'Should use Entity name (User) from related file',
      );
    });
  });
}

class TestProject {
  final Directory root;
  final AnalysisContextCollection collection;

  TestProject(this.root, this.collection);

  Future<ResolvedUnitResult> resolve(String relativePath) async {
    final fullPath = p.normalize(p.join(root.path, relativePath));
    final context = collection.contextFor(fullPath);
    return await context.currentSession.getResolvedUnit(fullPath) as ResolvedUnitResult;
  }

  void dispose() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}

/// Creates a temporary project with multiple files and returns a helper to resolve them.
/// [files]: Map of relative path -> content.
/// e.g. {'lib/main.dart': '...'}
Future<TestProject> setupProject(Map<String, String> files) async {
  final tempDir = Directory.systemTemp.createTempSync('arch_fix_test_');

  // Create pubspec
  File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('name: test_project');

  // Create files
  files.forEach((path, content) {
    final file = File(p.join(tempDir.path, path));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  });

  final collection = AnalysisContextCollection(includedPaths: [tempDir.path]);
  return TestProject(tempDir, collection);
}
