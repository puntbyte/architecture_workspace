// lib/src/lints/debug_component_identity.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Debugging lint that emits structured debug messages for many AST locations.
/// Implementation is split: the public rule is a small adapter, the heavy lifting
/// is performed by DebugRuleRunner and DebugReportGenerator.
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
    DebugRuleRunner(
      context: context,
      reporter: reporter,
      resolver: resolver,
      config: config,
      fileResolver: fileResolver,
      component: component,
    ).register();
  }
}

/// The runner sets up registry callbacks and uses small helpers to keep handlers tiny.
class DebugRuleRunner {
  final CustomLintContext context;
  final DiagnosticReporter reporter;
  final CustomLintResolver resolver;
  final ArchitectureConfig config;
  final FileResolver fileResolver;
  final ComponentContext? component;

  late final ReporterHelper _reporter;
  late final DebugReportGenerator _generator;

  DebugRuleRunner({
    required this.context,
    required this.reporter,
    required this.resolver,
    required this.config,
    required this.fileResolver,
    required this.component,
  }) {
    _reporter = ReporterHelper(reporter, DebugComponentIdentity._code);
    _generator = DebugReportGenerator(fileResolver: fileResolver, component: component);
  }

  void register() {
    // 1) File context header
    context.registry.addCompilationUnit(_onCompilationUnit);

    // 2) Directives
    context.registry.addImportDirective(_onImportDirective);
    context.registry.addExportDirective(_onExportDirective);
    context.registry.addAnnotation(_onAnnotation);

    // 3) Definitions
    context.registry.addClassDeclaration(_onClassDeclaration);
    context.registry.addMixinDeclaration(_onMixinDeclaration);
    context.registry.addEnumDeclaration(_onEnumDeclaration);
    context.registry.addExtensionDeclaration(_onExtensionDeclaration);
    context.registry.addConstructorDeclaration(_onConstructorDeclaration);
    context.registry.addFieldDeclaration(_onFieldDeclaration);
    // problem with usecase
    //context.registry.addMethodDeclaration(_onMethodDeclaration);
    //context.registry.addVariableDeclaration(_onVariableDeclaration);
    //context.registry.addFormalParameter(_onFormalParameter);

    // 4) Type references
    // problem with usecase
    //context.registry.addNamedType(_onNamedType);

    // 5) Flow & logic
    context.registry.addReturnStatement(_onReturnStatement);
    context.registry.addThrowExpression(_onThrowExpression);
    //context.registry.addMethodInvocation(_onMethodInvocation);
    //context.registry.addInstanceCreationExpression(_onInstanceCreation);
  }

  // ----------------------------
  // Handlers (very small, single-responsibility)
  // ----------------------------

  void _onCompilationUnit(CompilationUnit node) {
    final target = node.directives.firstOrNull ?? node.declarations.firstOrNull;
    if (target == null) return;

    // Use a token so the message is attached to a physical spot in file header
    final token = target.firstTokenAfterCommentAndMetadata;
    final message = _generator.generateHeaderReport(resolver.path);
    _reporter.reportOnToken(token, message);
  }

  void _onImportDirective(ImportDirective node) {
    final libImport = node.libraryImport;
    final importedLib = libImport?.importedLibrary;

    var info = '';
    if (importedLib != null) {
      info = 'Source: ${importedLib.firstFragment.source.fullName}';
    }

    final message = _generator.generate(
      typeLabel: 'Import',
      name: node.uri.stringValue ?? '???',
      path: resolver.path,
      dartType: null,
      element: null,
      astNode: null,
      extraInfo: info,
    );

    _reporter.reportOnNode(node.uri, message);
  }

  void _onExportDirective(ExportDirective node) {
    final message = _generator.generate(
      typeLabel: 'Export',
      name: node.uri.stringValue ?? '???',
      path: resolver.path,
    );
    _reporter.reportOnNode(node.uri, message);
  }

  void _onAnnotation(Annotation node) {
    final message = _generator.generate(
      typeLabel: 'Annotation',
      name: node.name.name,
      path: resolver.path,
      element: node.element,
    );
    _reporter.reportOnNode(node.name, message);
  }

  void _onClassDeclaration(ClassDeclaration node) {
    final message = _generator.generate(
      typeLabel: 'Class Def',
      name: node.name.lexeme,
      path: resolver.path,
      element: node.declaredFragment?.element,
      astNode: node,
    );
    _reporter.reportOnToken(node.name, message);
  }

  void _onMixinDeclaration(MixinDeclaration node) {
    final message = _generator.generate(
      typeLabel: 'Mixin Def',
      name: node.name.lexeme,
      path: resolver.path,
      element: node.declaredFragment?.element,
    );
    _reporter.reportOnToken(node.name, message);
  }

  void _onEnumDeclaration(EnumDeclaration node) {
    final message = _generator.generate(
      typeLabel: 'Enum Def',
      name: node.name.lexeme,
      path: resolver.path,
      element: node.declaredFragment?.element,
    );
    _reporter.reportOnToken(node.name, message);
  }

  void _onExtensionDeclaration(ExtensionDeclaration node) {
    final targetToken = node.name ?? node.firstTokenAfterCommentAndMetadata;
    final message = _generator.generate(
      typeLabel: 'Extension Def',
      name: node.name?.lexeme ?? '<unnamed>',
      path: resolver.path,
      element: node.declaredFragment?.element,
    );
    _reporter.reportOnToken(targetToken, message);
  }

  void _onConstructorDeclaration(ConstructorDeclaration node) {
    final target = node.name ?? node.returnType;
    final message = _generator.generate(
      typeLabel: 'Constructor',
      name: node.name?.lexeme ?? node.returnType.name,
      path: resolver.path,
      element: node.declaredFragment?.element,
    );
    _reporter.reportOnEntity(target, message);
  }

  void _onFieldDeclaration(FieldDeclaration node) {
    for (final variable in node.fields.variables) {
      final message = _generator.generate(
        typeLabel: 'Field',
        name: variable.name.lexeme,
        path: resolver.path,
        dartType: variable.declaredElement?.type,
        element: variable.declaredElement,
      );
      _reporter.reportOnToken(variable.name, message);
    }
  }

  void _onMethodDeclaration(MethodDeclaration node) {
    final message = _generator.generate(
      typeLabel: 'Method',
      name: node.name.lexeme,
      path: resolver.path,
      dartType: node.returnType?.type,
      element: node.declaredFragment?.element,
    );
    _reporter.reportOnToken(node.name, message);
  }

  void _onVariableDeclaration(VariableDeclaration node) {
    // Skip fields (they're handled by _onFieldDeclaration)
    if (node.parent?.parent is FieldDeclaration) return;

    final message = _generator.generate(
      typeLabel: 'Variable',
      name: node.name.lexeme,
      path: resolver.path,
      dartType: node.declaredElement?.type,
      element: node.declaredElement,
    );
    _reporter.reportOnToken(node.name, message);
  }

  void _onFormalParameter(FormalParameter node) {
    final name = node.name?.lexeme ?? '<unnamed>';
    final type = node.declaredFragment?.element.type;
    final message = _generator.generate(
      typeLabel: 'Parameter',
      name: name,
      path: resolver.path,
      dartType: type,
    );
    _reporter.reportOnEntity(node.name ?? node, message);
  }

  void _onNamedType(NamedType node) {
    // Avoid highlighting definitions themselves; keep inheritance highlights if desired
    if (node.parent is ClassDeclaration ||
        node.parent is ConstructorDeclaration ||
        node.parent is MethodDeclaration) {
      return;
    }

    final message = _generator.generate(
      typeLabel: 'Type Ref',
      name: node.name.lexeme,
      path: resolver.path,
      dartType: node.type,
      element: node.element,
    );
    _reporter.reportOnToken(node.name, message);
  }

  void _onReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression == null) return;

    var source = expression.toSource();
    if (source.length > 30) source = '${source.substring(0, 27)}...';

    final message = _generator.generate(
      typeLabel: 'Return',
      name: source,
      path: resolver.path,
      dartType: expression.staticType,
    );
    _reporter.reportOnNode(expression, message);
  }

  void _onThrowExpression(ThrowExpression node) {
    final type = node.expression.staticType;
    final message = _generator.generate(
      typeLabel: 'Throw',
      name: type?.getDisplayString() ?? 'dynamic',
      path: resolver.path,
      dartType: type,
    );
    _reporter.reportOnNode(node, message);
  }

  void _onMethodInvocation(MethodInvocation node) {
    final message = _generator.generate(
      typeLabel: 'Invocation',
      name: node.methodName.name,
      path: resolver.path,
      dartType: node.staticType,
      element: node.methodName.element,
    );
    _reporter.reportOnNode(node.methodName, message);
  }

  void _onInstanceCreation(InstanceCreationExpression node) {
    // For constructor expressions, prefer showing the ConstructorName token
    final cName = node.constructorName;
    final element = cName.name?.element; // named constructors may have a name token
    final message = _generator.generate(
      typeLabel: 'Instantiation',
      name: cName.toSource(),
      path: resolver.path,
      dartType: node.staticType,
      element: element,
    );

    _reporter.reportOnNode(cName, message);
  }
}

/// Thin helper that adapts reporter to AstNode/Token objects.
class ReporterHelper {
  final DiagnosticReporter _reporter;
  final LintCode _code;

  ReporterHelper(this._reporter, this._code);

  void reportOnNode(AstNode node, String message) {
    _reporter.atNode(node, _code, arguments: [message]);
  }

  void reportOnToken(Token token, String message) {
    _reporter.atToken(token, _code, arguments: [message]);
  }

  void reportOnEntity(SyntacticEntity entity, String message) {
    _reporter.atEntity(entity, _code, arguments: [message]);
  }
}

/// Generates debug report strings; extracted from the previous monolithic method.
class DebugReportGenerator {
  final FileResolver fileResolver;
  final ComponentContext? component;

  DebugReportGenerator({
    required this.fileResolver,
    required this.component,
  });

  /// Generates a short file-header style report used by compilation-unit handler.
  String generateHeaderReport(String path) {
    final sb = StringBuffer()
      ..writeln('[DEBUG: FILE CONTEXT] "${path.split('/').last}"')
      ..writeln('==================================================');

    if (component != null) {
      sb.writeln('✅ RESOLVED: "${component!.id}"');
      if (component!.module != null) {
        sb.writeln('📦 Module:   "${component!.module!.key}"');
      }
      sb.writeln('📂 Mode:     ${component!.config.mode.name}');
    } else {
      sb.writeln('❌ RESOLVED: <NULL> (Orphan File)');
    }

    sb.writeln('==================================================');
    return sb.toString();
  }

  /// General generator used by most node handlers.
  String generate({
    required String typeLabel,
    required String name,
    required String path,
    DartType? dartType,
    Element? element,
    AstNode? astNode,
    String? extraInfo,
  }) {
    final sb = StringBuffer()
      ..writeln('[DEBUG: $typeLabel] "$name"')
      ..writeln('==================================================');

    // Resolution result (component context)
    if (component != null) {
      sb.writeln('✅ RESOLVED: "${component!.id}"');
      if (component!.module != null) {
        sb.writeln('📦 Module:   "${component!.module!.key}"');
      }
      sb.writeln('📂 Mode:     ${component!.config.mode.name}');
    } else {
      sb.writeln('❌ RESOLVED: <NULL> (Orphan File)');
    }

    // Element & Type analysis
    if (dartType != null || element != null || extraInfo != null) {
      sb.writeln('\n🔬 ANALYSIS:');
      if (dartType != null) {
        sb.writeln('   • Type:    "${dartType.getDisplayString()}"');
        if (dartType.alias != null) {
          sb.writeln('   • Alias:   "${dartType.alias!.element.name}"');
        }
      }
      if (element != null) {
        final kindName = element.kind.displayName;
        sb.writeln('   • Element: "${element.name}" ($kindName)');

        final lib = element.library;
        if (lib != null) {
          final uri = lib.firstFragment.source.uri.toString();
          sb.writeln('   • Import:  "$uri"');
        }
      }
      if (extraInfo != null) {
        sb.writeln('   • Info:    $extraInfo');
      }
    }

    // Structural analysis for classes/mixins
    if (astNode is ClassDeclaration) {
      sb.writeln('\n🏗️ STRUCTURE:');
      final el = astNode.declaredFragment?.element;
      if (el != null) {
        sb
          ..writeln('   • Abstract? ${el.isAbstract}')
          ..writeln('   • Interface? ${el.isInterface}');

        final supertypes = el.allSupertypes
            .map((t) => t.element.name)
            .whereType<String>()
            .where((n) => n != 'Object')
            .toList();

        sb.writeln('   • Hierarchy: ${_formatList(supertypes)}');
      }
    }

    // Scoring log
    if (component?.debugScoreLog != null) {
      sb
        ..writeln('\n🧮 SCORING LOG:')
        ..write(component!.debugScoreLog!.trimRight());
    }

    sb.writeln('\n==================================================');
    return sb.toString();
  }

  String _formatList(List<String> items) {
    if (items.isEmpty) return '[]';
    return '[ ${items.join(", ")} ]';
  }
}
