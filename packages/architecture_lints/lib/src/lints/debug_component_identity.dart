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
    // Helper to report on any node with optional Type info
    void reportOn({
      required Object nodeOrToken, // AstNode or Token
      required String typeLabel,   // "Class", "Return Value", "Invocation"
      required String name,        // "User", "Future<void>"
      DartType? dartType,          // Optional: The static type being analyzed
    }) {
      final message = _generateDebugReport(
        typeLabel: typeLabel,
        name: name,
        path: resolver.path,
        component: component,
        dartType: dartType,
      );

      if (nodeOrToken is AstNode) {
        reporter.atNode(nodeOrToken, _code, arguments: [message]);
      } else if (nodeOrToken is Token) {
        reporter.atToken(nodeOrToken, _code, arguments: [message]);
      }
    }

    // --- 1. DEFINITIONS ---

    context.registry.addClassDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Class Def',
        name: node.name.lexeme,
      );
    });

    context.registry.addMethodDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Method Def',
        name: node.name.lexeme,
        dartType: node.returnType?.type,
      );
    });

    context.registry.addVariableDeclaration((node) {
      reportOn(
        nodeOrToken: node.name,
        typeLabel: 'Variable Def',
        name: node.name.lexeme,
        dartType: node.declaredElement?.type,
      );
    });

    context.registry.addFormalParameter((node) {
      final name = node.name?.lexeme ?? '<unnamed>';
      final type = node.declaredFragment?.element.type;
      reportOn(
        nodeOrToken: node,
        typeLabel: 'Parameter',
        name: name,
        dartType: type,
      );
    });

    // --- 2. EXPRESSIONS & FLOW (The Logic) ---

    // Returns: Highlight the actual value being returned
    context.registry.addReturnStatement((node) {
      final expression = node.expression;
      if (expression != null) {
        // Truncate source if too long
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

    // Throws
    context.registry.addThrowExpression((node) {
      final type = node.expression.staticType;
      reportOn(
        nodeOrToken: node,
        typeLabel: 'Throw',
        name: type?.getDisplayString() ?? 'dynamic',
        dartType: type,
      );
    });

    // Method Invocations (e.g. GetIt.I.get(), repo.getData())
    context.registry.addMethodInvocation((node) {
      reportOn(
        nodeOrToken: node.methodName,
        typeLabel: 'Invocation',
        name: node.methodName.name,
        dartType: node.staticType, // Shows what the method returns
      );
    });

    // Instantiations (e.g. AuthRepository())
    context.registry.addInstanceCreationExpression((node) {
      reportOn(
        nodeOrToken: node.constructorName,
        typeLabel: 'Instantiation',
        name: node.constructorName.toSource(),
        dartType: node.staticType, // Shows the type created
      );
    });
  }

  String _generateDebugReport({
    required String typeLabel,
    required String name,
    required String path,
    required ComponentContext? component,
    DartType? dartType,
  }) {
    final sb = StringBuffer();
    sb.writeln('[DEBUG REPORT: $typeLabel]');
    sb.writeln('Name/Source: "$name"');
    sb.writeln('--------------------------------------------------');

    // 1. RESOLUTION RESULT
    if (component != null) {
      sb.writeln('✅ Component ID: "${component.id}"');
      // sb.writeln('🏷️  Display Name: "${component.displayName}"');
      if (component.module != null) {
        sb.writeln('📦 Module:       "${component.module!.key}"');
      }
    } else {
      sb.writeln('❌ Component:    <NULL> (Orphan File)');
    }

    // 2. TYPE ANALYSIS (Crucial for TypeSafety rules)
    if (dartType != null) {
      sb.writeln('\n🔬 Type Analysis:');
      sb.writeln('   • Static Type: "${dartType.getDisplayString()}"');
      sb.writeln('   • Type Class:  "${dartType.runtimeType}"');

      final element = dartType.element;
      if (element != null) {
        // sb.writeln('   • Element:     "${element.name}" (${element.kind.displayName})');

        final lib = element.library;
        if (lib != null) {
          // Use firstFragment for Analyzer 6.0+ compatibility
          final uri = lib.firstFragment.source.uri.toString();
          sb.writeln('   • Source URI:  "$uri"');
        } else {
          sb.writeln('   • Source URI:  <Unknown Library>');
        }
      } else {
        sb.writeln('   • Element:     <Null> (Dynamic, Void, or Unresolved)');
      }

      if (dartType.alias != null) {
        sb.writeln('   • Type Alias:  "${dartType.alias!.element.name}"');
      }
    }

    // 3. CONFIG MATCHING PREVIEW
    if (component != null) {
      sb.writeln('\n🔗 Component Matching:');
      sb.writeln('   • "source"?               ${component.matchesReference("source")}');
      sb.writeln('   • "source.implementation"? ${component.matchesReference("source.implementation")}');
      sb.writeln('   • "data.source"?          ${component.matchesReference("data.source")}');
    }

    return sb.toString();
  }
}