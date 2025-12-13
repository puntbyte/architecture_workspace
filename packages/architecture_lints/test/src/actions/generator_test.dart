import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/code_generator.dart';
import 'package:architecture_lints/src/actions/logic/template_loader.dart';
import 'package:architecture_lints/src/config/schema/action_config.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/template_definition.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/mocks.dart';

class MockTemplateLoader extends Mock implements TemplateLoader {}

void main() {
  // FIX: Register fallback value for TemplateDefinition
  setUpAll(() {
    registerFallbackValue(const TemplateDefinition());
  });

  group('CodeGenerator', () {
    late MockTemplateLoader mockLoader;
    late ArchitectureConfig config;
    late CodeGenerator generator;
    late AstNode mockNode;

    setUp(() async {
      mockLoader = MockTemplateLoader();
      config = ArchitectureConfig(
        components: [],
        templates: {
          'test_template': const TemplateDefinition(content: 'Hello {{name}}!'),
          'file_template': const TemplateDefinition(filePath: 'tpl.mustache'),
        },
      );
      generator = CodeGenerator(config, mockLoader);

      final unit = await resolveContent('class World {}');
      mockNode = unit.unit.declarations.first;
    });

    test('should generate code from inline template', () async {
      final action = ActionConfig(
        id: 'test',
        description: '',
        trigger: const ActionTrigger(),
        target: const ActionTarget(directory: '.', filename: 'f.dart'),
        templateId: 'test_template',
        variables: {
          'name': 'source.name'
        },
      );

      // Now this works because fallback is registered
      when(() => mockLoader.loadContent(any())).thenReturn('Hello {{name}}!');

      final result = await generator.generate(action: action, sourceNode: mockNode);

      // Wrapper.toString() returns value, so Mustache renders 'World'
      expect(result, 'Hello World!');
    });

    test('should generate code from file template', () async {
      final action = ActionConfig(
        id: 'test_file',
        description: '',
        trigger: const ActionTrigger(),
        target: const ActionTarget(directory: '.', filename: 'f.dart'),
        templateId: 'file_template',
        variables: {
          'name': '"File"'
        },
      );

      // Stub file load
      when(() => mockLoader.loadContent(any())).thenReturn('From File: {{name}}');

      final result = await generator.generate(action: action, sourceNode: mockNode);

      expect(result, 'From File: File');
    });

    test('should return null if template ID not found', () async {
      final action = ActionConfig(
        id: 'missing',
        description: '',
        trigger: const ActionTrigger(),
        target: const ActionTarget(directory: '.', filename: 'f.dart'),
        templateId: 'unknown_id', // Does not exist
        variables: {},
      );

      final result = await generator.generate(action: action, sourceNode: mockNode);

      expect(result, isNull);
    });
  });
}