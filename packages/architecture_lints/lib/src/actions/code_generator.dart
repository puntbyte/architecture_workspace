// lib/src/actions/code_generator.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/actions/logic/mustache_renderer.dart';
import 'package:architecture_lints/src/actions/logic/template_loader.dart';
import 'package:architecture_lints/src/config/schema/action_config.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';

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
  /// NOW SYNCHRONOUS.
  String? generate({
    required ActionConfig action,
    required AstNode sourceNode,
  }) {
    // 1. Resolve Template Definition
    final templateDef = config.templates[action.templateId];
    if (templateDef == null) return null;

    // 2. Load Template Content (Sync)
    String templateString;
    try {
      templateString = templateLoader.loadContent(templateDef);
    } catch (e) {
      return null;
    }

    if (templateString.isEmpty) return null;

    // 3. Build Variable Context
    final resolver = VariableResolver(
      sourceNode: sourceNode,
      config: config,
      packageName: packageName,
    );

    final context = resolver.resolveMap(action.variables);

    // 4. Render Template
    final code = _renderer.render(templateString, context);

    // 5. Prepend Debug Header
    if (action.debug) {
      final debugHeader = _generateDebugHeader(context);
      return '$debugHeader\n$code';
    }

    return code;
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
      // Don't expand source unless asked, it's huge
      if (key == 'source' && indent.isEmpty) {
        buffer.writeln('// $key: <SourceWrapper>');
        return;
      }

      if (value is Map<String, dynamic>) {
        buffer.writeln('// $indent$key: {');
        _writeMap(buffer, value, '$indent  ');
        buffer.writeln('// $indent}');
      } else if (value is Iterable) {
        // Just print length to keep it clean
        buffer.writeln('// $indent$key: [List, length: ${value.length}]');
      } else {
        buffer.writeln('// $indent$key: "$value"');
      }
    });
  }
}

/*
void _writeMapOld(StringBuffer buffer, Map<String, dynamic> map, String indent) {
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        buffer.writeln('// $indent$key: {');
        _writeMap(buffer, value, '$indent  ');
        buffer.writeln('// $indent}');
      } else if (value is Iterable) {
        final listStr = value.map((e) => e.toString()).join(', ');
        final display = listStr.length > 100 ? '${listStr.substring(0, 97)}...' : listStr;
        buffer.writeln('// $indent$key: [$display] (Length: ${value.length})');
      } else {
        buffer.writeln('// $indent$key: "$value"');
      }
    });
  }


 */
