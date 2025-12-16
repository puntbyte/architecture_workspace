import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:architecture_lints/src/lints/architecture_fix.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_resolver.dart';

void main() {
  group('ArchitectureFix', () {
    late ArchitectureFix fix;
    late MockCustomLintResolver mockResolver;
    late MockChangeReporter mockReporter;
    late MockChangeBuilder mockChangeBuilder;
    late FakeCustomLintContext fakeContext;
    late FakeDartFileEditBuilder fakeEditBuilder;
    late MockDiagnostic mockError;
    late MockLintCode mockLintCode;

    setUp(() {
      fix = ArchitectureFix();
      mockResolver = MockCustomLintResolver();
      mockReporter = MockChangeReporter();
      mockChangeBuilder = MockChangeBuilder();
      fakeContext = FakeCustomLintContext();
      fakeEditBuilder = FakeDartFileEditBuilder();
      mockError = MockDiagnostic();
      mockLintCode = MockLintCode();

      // Wire up mocks
      when(() => mockError.diagnosticCode).thenReturn(mockLintCode);

      // When createChangeBuilder is called, return our mock builder
      when(
        () => mockReporter.createChangeBuilder(
          message: any(named: 'message'),
          priority: any(named: 'priority'),
        ),
      ).thenReturn(mockChangeBuilder);

      // When addDartFileEdit is called, execute the callback with our fake builder
      when(
        () => mockChangeBuilder.addDartFileEdit(
          any(),
          customPath: any(named: 'customPath'),
        ),
      ).thenAnswer((invocation) {
        final callback = invocation.positionalArguments.first as void Function(DartFileEditBuilder);
        callback(fakeEditBuilder);
      });
    });

    Future<void> prepareEnvironment({
      required String dartCode,
      required String yamlConfig,
      required String errorCode,
      String? targetClassName,
    }) async {
      // 1. Resolve Dart Code (AST)
      final result = await resolveContent(dartCode);

      // 2. CRITICAL FIX: Write architecture.yaml to disk
      // This allows ConfigLoader.findRootPath to succeed inside ArchitectureFix
      final rootDir = File(result.path).parent.parent; // Up from lib/test.dart to root
      final configFile = File(p.join(rootDir.path, 'architecture.yaml'))
        ..writeAsStringSync(yamlConfig);

      // 3. Setup Config (Manual Parse for Shared State injection)
      final yamlMap = loadYaml(yamlConfig) as Map;
      final config = ArchitectureConfig.fromYaml(yamlMap);

      // 4. Populate Shared State
      fakeContext.sharedState[ArchitectureConfig] = config;
      fakeContext.sharedState[ResolvedUnitResult] = result;

      // 5. Configure Mocks
      when(() => mockResolver.path).thenReturn(result.path);
      when(() => mockResolver.getResolvedUnitResult()).thenAnswer((_) async => result);
      when(() => mockLintCode.name).thenReturn(errorCode);

      // 6. Find error offset
      final unit = result.unit;
      final node = targetClassName != null
          ? unit.declarations.whereType<ClassDeclaration>().firstWhere(
              (c) => c.name.lexeme == targetClassName,
            )
          : unit.declarations.first;

      when(() => mockError.offset).thenReturn(node.offset);
      when(() => mockError.length).thenReturn(node.length);
    }

    test('should inject code into current file (Strategy: inject)', () async {
      const yaml = r'''
      actions:
        add_method:
          description: 'Add Method'
          trigger: { error_code: 'missing_method' }
          target: { scope: 'current' }
          write: { strategy: 'inject', placement: 'end' }
          variables:
            className: ${source.name}
          template_id: 'method_tmpl'
      
      templates:
        method_tmpl: 'void generated() {}'
      ''';

      const code = '''
      class User {}
      ''';

      await prepareEnvironment(
        dartCode: code,
        yamlConfig: yaml,
        errorCode: 'missing_method',
        targetClassName: 'User',
      );

      // Run
      fix.run(mockResolver, mockReporter, fakeContext, mockError, []);

      // Verify
      verify(
        () => mockReporter.createChangeBuilder(message: 'Add Method', priority: 100),
      ).called(1);

      expect(fakeEditBuilder.output.toString(), contains('void generated() {}'));
      // Should be inserted inside the class (offset checks would confirm placement)
    });

    test('should create new file (Strategy: file)', () async {
      const yaml = r'''
      actions:
        create_model:
          description: 'Create Model'
          trigger: { error_code: 'missing_model' }
          target: { scope: 'related' } # Just to test file creation logic
          write: 
            strategy: 'file'
            filename: '${source.name.snakeCase}_model.dart'
          variables:
            modelName: '${source.name}Model'
          template_id: 'model_tmpl'
      
      templates:
        model_tmpl: 'class {{modelName}} {}'
      ''';

      const code = '''
      class User {}
      ''';

      await prepareEnvironment(
        dartCode: code,
        yamlConfig: yaml,
        errorCode: 'missing_model',
        targetClassName: 'User',
      );

      // Run
      fix.run(mockResolver, mockReporter, fakeContext, mockError, []);

      // Verify customPath was passed
      final captured = verify(
        () => mockChangeBuilder.addDartFileEdit(
          any(),
          customPath: captureAny(named: 'customPath'),
        ),
      ).captured;

      final customPath = captured.first as String;

      expect(customPath, endsWith('user_model.dart'));
      expect(fakeEditBuilder.output.toString(), contains('class UserModel {}'));
    });

    test('should ignore actions with mismatching error code', () async {
      const yaml = '''
      actions:
        wrong_action:
          description: 'Should not run'
          trigger: { error_code: 'other_error' }
          target: { scope: 'current' }
          write: { strategy: 'inject' }
          variables: {}
          template_id: 't'
      templates:
        t: ''
      ''';

      await prepareEnvironment(
        dartCode: 'class A {}',
        yamlConfig: yaml,
        errorCode: 'my_error', // Mismatch
      );

      fix.run(mockResolver, mockReporter, fakeContext, mockError, []);

      verifyNever(
        () => mockReporter.createChangeBuilder(
          message: any(named: 'message'),
          priority: any(named: 'priority'),
        ),
      );
    });

    test('should resolve variables using expression engine', () async {
      const yaml = '''
      actions:
        test_vars:
          description: 'Test Vars'
          trigger: { error_code: 'var_test' }
          target: { scope: 'current' }
          write: { strategy: 'replace' }
          variables:
            # Complex expression
            result: "source.name.pascalCase + 'Fixed'"
          template_id: 't'
      templates:
        t: '{{result}}'
      ''';

      await prepareEnvironment(
        dartCode: 'class user_profile {}',
        yamlConfig: yaml,
        errorCode: 'var_test',
        targetClassName: 'user_profile',
      );

      fix.run(mockResolver, mockReporter, fakeContext, mockError, []);

      expect(fakeEditBuilder.output.toString(), 'UserProfileFixed');
    });
  });
}
