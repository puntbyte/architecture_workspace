import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/code_generator.dart';
import 'package:architecture_lints/src/actions/logic/template_loader.dart';
import 'package:architecture_lints/src/config/enums/action_scope.dart';
import 'package:architecture_lints/src/config/enums/variable_type.dart';
import 'package:architecture_lints/src/config/enums/write_strategy.dart';
import 'package:architecture_lints/src/config/schema/action_config.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/template_definition.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/test_resolver.dart';

// 1. Mocks & Fakes
class MockTemplateLoader extends Mock implements TemplateLoader {}
class FakeTemplateDefinition extends Fake implements TemplateDefinition {}

void main() {
  group('CodeGenerator', () {
    late MockTemplateLoader mockLoader;
    late ArchitectureConfig config;
    late CodeGenerator generator;
    late AstNode sourceNode;

    // FIX: Register fallback value for mocktail
    setUpAll(() {
      registerFallbackValue(FakeTemplateDefinition());
    });

    // Helper to create a minimal valid ActionConfig
    ActionConfig createAction({
      required String templateId,
      Map<String, VariableConfig> variables = const {},
      bool debug = false,
    }) {
      return ActionConfig(
        id: 'test_action',
        description: 'Test',
        trigger: const ActionTrigger(),
        source: const ActionSource(),
        target: const ActionTarget(scope: ActionScope.current),
        write: const ActionWrite(
          strategy: WriteStrategy.file,
          filename: 'test.dart',
        ),
        variables: variables,
        templateId: templateId,
        debug: debug,
      );
    }

    setUp(() async {
      mockLoader = MockTemplateLoader();

      // 1. Setup Source Node (Class 'User')
      const code = 'class User {}';
      final unit = await resolveContent(code);
      sourceNode = unit.unit.declarations.first;

      // 2. Setup Config
      config = const ArchitectureConfig(
        components: [],
        templates: {
          'simple_template': TemplateDefinition(content: 'Hello {{name}}!'),
          'file_template': TemplateDefinition(filePath: 'templates/tmpl.mustache'),
        },
      );

      // 3. Initialize Generator
      generator = CodeGenerator(config, mockLoader, 'test_pkg');
    });

    test('should return null if template definition is missing in config', () async {
      final action = createAction(templateId: 'missing_id');

      final result = generator.generate(action: action, sourceNode: sourceNode);

      expect(result, isNull);
      verifyZeroInteractions(mockLoader);
    });

    test('should return null if template loader throws or returns empty', () async {
      final action = createAction(templateId: 'file_template');

      when(() => mockLoader.loadContent(any())).thenThrow(StateError('File not found'));

      final result = generator.generate(action: action, sourceNode: sourceNode);
      expect(result, isNull);
    });

    test('should generate code with resolved variables', () async {
      final action = createAction(
        templateId: 'simple_template',
        variables: {
          'name': const VariableConfig(
            type: VariableType.string,
            value: r'${source.name}', // Resolves to "User"
          ),
        },
      );

      // Mock loader to return content for the definition found in config
      when(() => mockLoader.loadContent(any())).thenReturn('Hello {{name}}!');

      final result = generator.generate(action: action, sourceNode: sourceNode);

      expect(result, 'Hello User!');
    });

    test('should support complex variable logic (Casing)', () async {
      final action = createAction(
        templateId: 'simple_template',
        variables: {
          'name': const VariableConfig(
            type: VariableType.string,
            value: r'${source.name.snakeCase}', // Resolves to "user"
          ),
        },
      );

      when(() => mockLoader.loadContent(any())).thenReturn('File: {{name}}.dart');

      final result = generator.generate(action: action, sourceNode: sourceNode);

      expect(result, 'File: user.dart');
    });

    test('should prepend debug header when debug is true', () async {
      final action = createAction(
        templateId: 'simple_template',
        debug: true,
        variables: {
          'name': const VariableConfig(type: VariableType.string, value: "'DebugUser'"),
        },
      );

      when(() => mockLoader.loadContent(any())).thenReturn('Code {{name}}');

      final result = generator.generate(action: action, sourceNode: sourceNode);

      expect(result, contains('// [DEBUG] GENERATION CONTEXT'));
      expect(result, contains('// name: "DebugUser"'));
      expect(result, contains('Code DebugUser'));
    });

    test('should handle Map variables in debug output', () async {
      final action = createAction(
        templateId: 'simple_template',
        debug: true,
        variables: {
          'config': const VariableConfig(
            type: VariableType.map,
            children: {
              'key': VariableConfig(type: VariableType.string, value: "'value'"),
            },
          ),
        },
      );

      when(() => mockLoader.loadContent(any())).thenReturn('...');

      final result = generator.generate(action: action, sourceNode: sourceNode);

      // Check indentation format
      expect(result, contains('// config: {'));
      expect(result, contains('//   key: "value"'));
      expect(result, contains('// }'));
    });
  });
}
