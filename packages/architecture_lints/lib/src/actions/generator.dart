import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/source_wrapper.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/actions/logic/mustache_renderer.dart';
import 'package:architecture_lints/src/actions/logic/template_loader.dart';
import 'package:architecture_lints/src/config/schema/action_config.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';

class CodeGenerator {
  final ArchitectureConfig config;
  final TemplateLoader templateLoader;
  final MustacheRenderer _renderer;

  CodeGenerator(this.config, this.templateLoader) : _renderer = const MustacheRenderer();

  /// Generates code based on the [action] configuration and the [sourceNode] context.
  Future<String?> generate({
    required ActionConfig action,
    required AstNode sourceNode,
  }) async {
    // 1. Resolve Template Definition
    final templateDef = config.templates[action.templateId];
    // In a real app, you might want to log this missing configuration

    if (templateDef == null) return null;

    // 2. Load Template Content (Inline or File)
    final templateString = await templateLoader.loadContent(templateDef);
    if (templateString.isEmpty) return null;

    // 3. Build Variable Context
    final sourceWrapper = SourceWrapper(sourceNode);

    // Initialize resolver with AST source and global config (for definitions/annotations lookup)
    final resolver = VariableResolver(sourceWrapper, config);

    // Resolve the 'variables' section from YAML into a JSON-like map
    final context = resolver.resolveMap(action.variables);

    // 4. Render Template
    return _renderer.render(templateString, context);
  }
}
