import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/engines/template/mustache_renderer.dart';
import 'package:architecture_lints/src/engines/template/template_loader.dart';
import 'package:architecture_lints/src/engines/variable/variable_resolver.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/action_definition.dart';
import 'package:dart_style/dart_style.dart';

class CodeGenerator {
  final ArchitectureConfig config;
  final TemplateLoader templateLoader;
  final MustacheRenderer _renderer;
  final String packageName;

  CodeGenerator(
      this.config,
      this.templateLoader,
      this.packageName,
      ) : _renderer = const MustacheRenderer();

  /// Generates code based on the [action] configuration.
  /// Pure transformation: AST -> String.
  Future<String?> generate({
    required ActionDefinition action,
    required AstNode sourceNode,
  }) async {
    // 1. Resolve Template Definition
    final templateDef = config.templates[action.templateId];
    if (templateDef == null) return null;

    // 2. Load Template Content
    String templateString;
    try {
      templateString = templateLoader.loadContent(templateDef);
    } catch (e) {
      return null;
    }
    if (templateString.isEmpty) return null;

    // 3. Build Variable Context
    // We assume sourceNode is already the "Effective Node" (switched if needed)
    final resolver = VariableResolver(
      sourceNode: sourceNode,
      config: config,
      packageName: packageName,
    );

    Map<String, dynamic> context;
    try {
      context = resolver.resolveMap(action.variables);
    } catch (e) {
      return null;
    }

    // 4. Render Template
    final codeBody = _renderer.render(templateString, context);

    // 5. Debug Header
    final fullCode = action.debug
        ? '${_generateDebugHeader(context)}\n$codeBody'
        : codeBody;

    // 6. Format
    if (action.format) {
      try {
        final formatter = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
          pageWidth: action.formatLineLength ?? 80,
        );
        return formatter.format(fullCode);
      } catch (e) {
        if (action.debug) return '/* Format Error: $e */\n$fullCode';
        return fullCode;
      }
    }

    return fullCode;
  }

  String _generateDebugHeader(Map<String, dynamic> context) {
    final buffer = StringBuffer()
      ..writeln('// ==========================================')
      ..writeln('// [DEBUG] GENERATION CONTEXT')
      ..writeln('// ==========================================');
    _writeMap(buffer, context, '');
    buffer.writeln('// ==========================================\n');
    return buffer.toString();
  }

  void _writeMap(StringBuffer buffer, Map<String, dynamic> map, String indent) {
    map.forEach((key, value) {
      if (key == 'source' && indent.isEmpty) {
        buffer.writeln('// $key: <SourceWrapper>');
        return;
      }
      if (value is Map<String, dynamic>) {
        buffer.writeln('// $indent$key: {');
        _writeMap(buffer, value, '$indent  ');
        buffer.writeln('// $indent}');
      } else if (value is Iterable) {
        buffer.writeln('// $indent$key: [List, length: ${value.length}]');
      } else {
        buffer.writeln('// $indent$key: "$value"');
      }
    });
  }
}