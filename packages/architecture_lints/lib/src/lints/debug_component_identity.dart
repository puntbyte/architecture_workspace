import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';
// Hide LintCode to avoid conflict
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DebugComponentIdentity extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'debug_component_identity',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.INFO,
  );

  const DebugComponentIdentity() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    void reportOn({
      required Object nodeOrToken,
      required String typeLabel,
      required String name,
      DartType? dartType,
      AstNode? astNode,
    }) {
      final message = _generateDebugReport(
        typeLabel: typeLabel,
        name: name,
        path: resolver.path,
        component: component,
        dartType: dartType,
        astNode: astNode,
        fileResolver: fileResolver,
      );

      if (nodeOrToken is AstNode) {
        reporter.atNode(nodeOrToken, _code, arguments: [message]);
      } else if (nodeOrToken is Token) {
        reporter.atToken(nodeOrToken, _code, arguments: [message]);
      }
    }

    // --- 0. FILE HEADER (Guaranteed Visibility) ---
    context.registry.addCompilationUnit((node) {
      // Try to find the first directive (import/export/part)
      final firstNode = node.directives.firstOrNull ??
          node.declarations.firstOrNull; // Or first class

      if (firstNode != null) {
        reportOn(
          nodeOrToken: firstNode,
          typeLabel: 'FILE RESOLUTION',
          name: resolver.path.split('/').last,
        );
      }
    });

    // --- 1. DEFINITIONS ---

    context.registry.addClassDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Class Definition',
        name: node.name.lexeme,
        astNode: node,
      );
    });

    context.registry.addMethodDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Method Definition',
        name: node.name.lexeme,
        dartType: node.returnType?.type,
      );
    });

    context.registry.addVariableDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Variable Definition',
        name: node.name.lexeme,
        dartType: node.declaredElement?.type,
      );
    });

    // Highlight Type Aliases (typedefs)
    context.registry.addGenericTypeAlias((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Typedef',
        name: node.name.lexeme,
        astNode: node,
      );
    });

    context.registry.addFunctionTypeAlias((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Typedef (Legacy)',
        name: node.name.lexeme,
        astNode: node,
      );
    });

    // --- 2. EXPRESSIONS & FLOW ---

    context.registry.addReturnStatement((node) {
      final expression = node.expression;
      if (expression != null) {
        var source = expression.toSource();
        if (source.length > 30) source = '${source.substring(0, 27)}...';
        reportOn(
          nodeOrToken: expression,
          typeLabel: 'Return Value',
          name: source,
          dartType: expression.staticType,
        );
      }
    });

    context.registry.addThrowExpression((node) {
      final type = node.expression.staticType;
      reportOn(
        nodeOrToken: node,
        typeLabel: 'Throw',
        name: type?.getDisplayString() ?? 'dynamic',
        dartType: type,
      );
    });

    context.registry.addMethodInvocation((node) {
      reportOn(
        nodeOrToken: node.methodName,
        typeLabel: 'Invocation',
        name: node.methodName.name,
        dartType: node.staticType,
      );
    });

    context.registry.addInstanceCreationExpression((node) {
      reportOn(
        nodeOrToken: node.constructorName,
        typeLabel: 'Instantiation',
        name: node.constructorName.toSource(),
        dartType: node.staticType,
      );
    });
  }

  String _generateDebugReport({
    required String typeLabel,
    required String name,
    required String path,
    required ComponentContext? component,
    required FileResolver fileResolver,
    DartType? dartType,
    AstNode? astNode,
  }) {
    final sb = StringBuffer();
    sb.writeln('[DEBUG: $typeLabel] "$name"');
    sb.writeln('==================================================');

    // 1. RESOLUTION RESULT
    if (component != null) {
      sb.writeln('✅ RESOLVED: "${component.id}"');
      if (component.module != null) {
        sb.writeln('📦 Module:   "${component.module!.key}"');
      }
      sb.writeln('📂 Mode:     ${component.config.mode.name}');
    } else {
      sb.writeln('❌ RESOLVED: <NULL> (Orphan)');
    }

    // 2. SCORING LOG
    if (component?.debugScoreLog != null) {
      sb.writeln('\n🧮 SCORING LOG:');
      sb.writeln(component!.debugScoreLog!.trimRight());
    } else {
      // Fallback
      final candidates = fileResolver.resolveAllCandidates(path);
      sb.writeln('\n📊 COMPETITION (Raw Path Match):');
      if (candidates.isEmpty) {
        sb.writeln('   (No components match path)');
      } else {
        for (final c in candidates) {
          final isWinner = component?.id == c.component.id;
          sb.writeln('${isWinner ? "➤" : " "} ${c.component.id} (Idx:${c.matchIndex}, Len:${c.matchLength})');
        }
      }
    }

    // 3. STRUCTURE ANALYSIS
    if (astNode is ClassDeclaration) {
      sb.writeln('\n🏗️ CLASS STRUCTURE:');
      final element = astNode.declaredFragment?.element;
      if (element != null) {
        sb.writeln('   • Name: "${element.name}"');
        sb.writeln('   • Abstract? ${element.isAbstract}');
        sb.writeln('   • Interface? ${element.isInterface}');
        final supertypes = element.allSupertypes
            .map((t) => t.element.name)
            .where((n) => n != 'Object')
            .join(', ');
        sb.writeln('   • Hierarchy: [ $supertypes ]');
      }
    }

    sb.writeln('==================================================');
    return sb.toString();
  }
}