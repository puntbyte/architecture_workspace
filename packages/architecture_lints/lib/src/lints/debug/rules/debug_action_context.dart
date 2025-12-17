import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/engines/file/file.dart';
import 'package:architecture_lints/src/engines/variable/variable.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/lints/debug/utils/reporter_helper.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/enums/action_element.dart';
import 'package:architecture_lints/src/schema/enums/action_scope.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DebugActionContext extends ArchitectureRule with DebugComponentIdentityWrapper {
  static const _code = LintCode(
    name: 'debug_action_context',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  const DebugActionContext() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    if (component == null) return;

    final helper = ReporterHelper(reporter, _code);
    final packageName = context.pubspec.name;

    // Helper to check and report actions
    void checkNode(AstNode node, ActionElement elementType) {
      // Find actions that match this component + element type
      final applicableActions = config.actions.where((action) {
        // 1. Check Component Match
        if (action.trigger.component != null) {
          if (!component.matchesReference(action.trigger.component!)) return false;
        }

        // 2. Check Element Type
        if (action.trigger.element != null) {
          final triggerKind = action.trigger.element;
          if (triggerKind != elementType) return false;
        }

        return true;
      }).toList();

      if (applicableActions.isEmpty) return;

      for (final action in applicableActions) {
        final sb = StringBuffer()
          ..writeln('[DEBUG: ACTION] "${action.id}"')
          ..writeln('--------------------------------------------------')
          ..writeln('Description: ${action.description}')
          ..writeln(
            'Trigger:     ${action.trigger.component ?? "*"} (${action.trigger.element ?? "*"})',
          )
          ..writeln('Error Code:  ${action.trigger.errorCode ?? "N/A"}');

        if (action.source.scope == ActionScope.related) {
          sb
            ..writeln('⚠️ SCOPE: RELATED')
            ..writeln('   Variables below are resolved against THIS node for debugging.')
            ..writeln('   Actual execution will switch context to: ${action.source.component}');
        }

        sb.writeln('\nVARIABLES:');

        try {
          final resolver = VariableResolver(
            sourceNode: node,
            config: config,
            packageName: packageName,
          );

          final variables = resolver.resolveMap(action.variables);
          _writeMap(sb, variables, '   ');
        } catch (e) {
          sb.writeln('   ❌ Resolution Failed: $e');
        }

        sb
          ..writeln('\nTEMPLATE:')
          ..writeln('   ID: ${action.templateId}');
        final template = config.templates[action.templateId];
        if (template != null) {
          if (template.filePath != null) {
            sb.writeln('   File: ${template.filePath}');
          } else {
            sb.writeln('   (Inline Content)');
          }
        } else {
          sb.writeln('   ❌ MISSING TEMPLATE DEFINITION');
        }

        sb.writeln('==================================================');

        // Extract token safely
        final token = _getNameToken(node);

        helper.reportOnToken(token ?? node.beginToken, sb.toString());
      }
    }

    // Register Listeners
    context.registry.addClassDeclaration((node) => checkNode(node, ActionElement.clazz));
    context.registry.addMethodDeclaration((node) => checkNode(node, ActionElement.method));
    context.registry.addFieldDeclaration((node) => checkNode(node, ActionElement.field));
    context.registry.addConstructorDeclaration(
      (node) => checkNode(node, ActionElement.constructor),
    );
  }

  /// Type-safe extraction of the name token
  Token? _getNameToken(AstNode node) {
    if (node is NamedCompilationUnitMember) {
      // Classes, Mixins, Enums, Extensions
      return node.name;
    } else if (node is MethodDeclaration) {
      return node.name;
    } else if (node is ConstructorDeclaration) {
      return node.name ?? node.returnType.beginToken;
    } else if (node is VariableDeclaration) {
      return node.name;
    } else if (node is FieldDeclaration) {
      // Highlight the first variable in the field list
      return node.fields.variables.firstOrNull?.name;
    }
    return null;
  }

  void _writeMap(StringBuffer buffer, Map<String, dynamic> map, String indent) {
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        buffer.writeln('$indent• $key: {');
        _writeMap(buffer, value, '$indent  ');
        buffer.writeln('$indent  }');
      } else if (value is Iterable) {
        final listStr = value.take(5).join(', ');
        final suffix = value.length > 5 ? '... (+${value.length - 5})' : '';
        buffer.writeln('$indent• $key: [$listStr$suffix]');
      } else {
        buffer.writeln('$indent• $key: "$value"');
      }
    });
  }
}
