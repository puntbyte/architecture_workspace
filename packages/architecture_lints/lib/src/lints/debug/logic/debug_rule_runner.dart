import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/lints/debug/logic/debug_report_generator.dart';
import 'package:architecture_lints/src/lints/debug/utils/reporter_helper.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DebugRuleRunner {
  final CustomLintContext context;
  final DiagnosticReporter reporter;
  final CustomLintResolver resolver;
  final ArchitectureConfig config;
  final FileResolver fileResolver;
  final ComponentContext? component;
  final String? globalError;

  late final ReporterHelper _reporter;
  late final DebugReportGenerator _generator;

  DebugRuleRunner({
    required this.context,
    required this.reporter,
    required this.resolver,
    required this.config,
    required this.fileResolver,
    required this.component,
    required LintCode code,
    this.globalError,
  }) {
    _reporter = ReporterHelper(reporter, code);
    _generator = DebugReportGenerator(
      config: config,
      fileResolver: fileResolver,
      component: component,
      error: globalError,
    );
  }

  void register() {
    // 1) File Header
    context.registry.addCompilationUnit(_onCompilationUnit);

    // 2) Directives
    context.registry.addImportDirective(_onImportDirective);
    context.registry.addExportDirective(_onExportDirective);
    context.registry.addAnnotation(_onAnnotation);

    // 3) Declarations
    context.registry.addClassDeclaration(_onClassDeclarationType);
    context.registry.addMixinDeclaration(_onMixinDeclaration);
    context.registry.addEnumDeclaration(_onEnumDeclaration);
    context.registry.addExtensionDeclaration(_onExtensionDeclaration);
    context.registry.addConstructorDeclaration(_onConstructorDeclaration);
    context.registry.addFieldDeclaration(_onFieldDeclarationIdentifier);
    //context.registry.addMethodDeclaration(_onMethodDeclarationIdentifier);
    //context.registry.addMethodDeclaration(_onMethodDeclarationReturnType);
    //context.registry.addFormalParameter(_onFormalParameterIdentifier);

    // 4) Logic & Types
    //context.registry.addNamedType(_onNamedType);
    //context.registry.addReturnStatement(_onReturnStatement);
    //context.registry.addThrowExpression(_onThrowExpression);
    //context.registry.addMethodInvocation(_onMethodInvocation);
    //context.registry.addInstanceCreationExpression(_onInstanceCreation);
  }

  // ----------------------------
  // Handlers
  // ----------------------------

  void _onCompilationUnit(CompilationUnit node) {
    Token? targetToken;

    // Strategy: Find comment starting with "// lib/"
    Token? comment = node.beginToken.precedingComments;
    while (comment != null) {
      final lexeme = comment.lexeme.trim();
      if (lexeme.startsWith('// lib/') ||
          lexeme.startsWith('/// lib/') ||
          lexeme.startsWith('//lib/')) {
        targetToken = comment;
        break;
      }
      comment = comment.next;
    }

    if (targetToken == null) {
      final child = node.directives.firstOrNull ?? node.declarations.firstOrNull;
      if (child != null) targetToken = child.firstTokenAfterCommentAndMetadata;
    }
    targetToken ??= node.beginToken;

    final message = _generator.generateHeaderReport(resolver.path);
    _reporter.reportOnToken(targetToken, message);
  }

  void _onImportDirective(ImportDirective node) {
    final targetNode = node.uri;
    final importedLib = node.libraryImport?.importedLibrary;
    var info = '';
    if (importedLib != null) info = 'Source: ${importedLib.firstFragment.source.fullName}';

    final message = _generator.generate(
      typeLabel: 'Import',
      name: targetNode.stringValue ?? '???',
      path: resolver.path,
      extraInfo: info,
    );

    _reporter.reportOnNode(targetNode, message);
  }

  void _onExportDirective(ExportDirective node) {
    final targetNode = node.uri;
    final message = _generator.generate(
      typeLabel: 'Export',
      name: targetNode.stringValue ?? '???',
      path: resolver.path,
    );
    _reporter.reportOnNode(targetNode, message);
  }

  void _onAnnotation(Annotation node) {
    final targetNode = node.name;
    final message = _generator.generate(
      typeLabel: 'Annotation',
      name: targetNode.name,
      path: resolver.path,
      element: node.element,
    );
    _reporter.reportOnNode(targetNode, message);
  }

  void _onClassDeclarationType(ClassDeclaration node) {
    final targetToken = node.name;
    final message = _generator.generate(
      typeLabel: 'Class Declaration Type',
      name: targetToken.lexeme,
      path: resolver.path,
      element: node.declaredFragment?.element,
      astNode: node,
    );
    _reporter.reportOnToken(targetToken, message);
  }

  void _onMixinDeclaration(MixinDeclaration node) {
    final targetToken = node.name;
    final message = _generator.generate(
      typeLabel: 'Mixin Def',
      name: targetToken.lexeme,
      path: resolver.path,
      element: node.declaredFragment?.element,
    );
    _reporter.reportOnToken(targetToken, message);
  }

  void _onEnumDeclaration(EnumDeclaration node) {
    final targetToken = node.name;
    final message = _generator.generate(
      typeLabel: 'Enum Def',
      name: targetToken.lexeme,
      path: resolver.path,
      element: node.declaredFragment?.element,
    );
    _reporter.reportOnToken(targetToken, message);
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
    final targetEntity = node.name ?? node.returnType;
    final message = _generator.generate(
      typeLabel: 'Constructor Declaration',
      name: node.name?.lexeme ?? node.returnType.name,
      path: resolver.path,
      element: node.declaredFragment?.element,
      astNode: node, // Pass AST node for detailed details
    );
    _reporter.reportOnEntity(targetEntity, message);
  }

  void _onFieldDeclarationIdentifier(FieldDeclaration node) {
    for (final variable in node.fields.variables) {
      final targetToken = variable.name;

      final message = _generator.generate(
        typeLabel: 'Field Declaration Identifier',
        name: targetToken.lexeme,
        path: resolver.path,
        dartType: variable.declaredElement?.type,
        element: variable.declaredElement,
        astNode: node,
      );

      _reporter.reportOnToken(targetToken, message);
    }
  }

  void _onMethodDeclarationIdentifier(MethodDeclaration node) {
    final targetToken = node.name;

    final message = _generator.generate(
      typeLabel: 'Method Declaration Identifier',
      name: targetToken.lexeme,
      path: resolver.path,
      dartType: node.returnType?.type,
      // Often used for return type display
      element: node.declaredFragment?.element,
      astNode: node,
    );
    _reporter.reportOnToken(targetToken, message);
  }

  void _onMethodDeclarationReturnType(MethodDeclaration node) {
    final targetToken = node.returnType?.beginToken;

    if (targetToken == null) return;

    final message = _generator.generate(
      typeLabel: 'Method Declaration Return Type',
      name: targetToken.runtimeType.toString(),
      path: resolver.path,
      dartType: node.returnType?.type,
      element: node.returnType?.type?.element,
      astNode: node,
    );

    _reporter.reportOnToken(targetToken, message);
  }

  void _onFormalParameterIdentifier(FormalParameter node) {
    // Avoid double reporting: DefaultFormalParameter wraps a NormalFormalParameter.
    // We only report the outer DefaultFormalParameter to cover the full range (including = value).
    if (node.parent is DefaultFormalParameter) return;

    final name = node.name?.lexeme ?? '<unnamed>';
    final type = node.declaredFragment?.element.type;

    // Determine Context (Constructor vs Method)

    var parent = node.parent;
    var label = 'Parameter Identifier';

    while (parent != null) {
      if (parent is ConstructorDeclaration) {
        label += ' (Constructor)';
        break;
      } else if (parent is MethodDeclaration) {
        label += ' (Method)';
        break;
      } else if (parent is FunctionDeclaration || parent is FunctionExpression) {
        label += ' (Function)';
        break;
      }

      // Stop optimization: If we hit a class/mixin/enum, we've gone too far.
      if (parent is ClassDeclaration || parent is MixinDeclaration || parent is EnumDeclaration) {
        break;
      }

      parent = parent.parent;
    }

    final message = _generator.generate(
      typeLabel: label,
      name: name,
      path: resolver.path,
      dartType: type,
      element: node.declaredFragment?.element,
      astNode: node,
    );

    if (node.name != null) {
      _reporter.reportOnToken(node.name!, message);
    } else {
      _reporter.reportOnNode(node, message);
    }
  }

  void _onNamedType(NamedType node) {
    final targetToken = node.name;
    final parent = node.parent;

    final label = switch (parent) {
      ExtendsClause() => 'Extends Clause Type',
      ImplementsClause() => 'Implements Clause Type',
      WithClause() => 'With (Mixin) Clause Type',
      GenericTypeAlias() => 'Typedef Type',
      SimpleFormalParameter() => 'Simple Formal Parameter Type',
      TypeArgumentList() => 'Type Argument',
      // Bypass class fields type
      VariableDeclarationList() when parent.parent is FieldDeclaration => null,
      // Bypass instance creations of classes in method body
      ConstructorName() when parent.parent is InstanceCreationExpression => null,
      _ => 'Type Ref (${parent.runtimeType})',
    };

    if (label == null) return;

    final message = _generator.generate(
      typeLabel: label,
      name: targetToken.lexeme,
      path: resolver.path,
      dartType: node.type,
      element: node.element,
      astNode: node,
    );

    _reporter.reportOnToken(targetToken, message);
  }

  void _onReturnStatement(ReturnStatement node) {
    final targetNode = node.expression;
    if (targetNode == null) return;
    final message = _generator.generate(
      typeLabel: 'Return',
      name: 'Expression',
      path: resolver.path,
      dartType: targetNode.staticType,
    );
    _reporter.reportOnNode(targetNode, message);
  }

  void _onThrowExpression(ThrowExpression node) {
    final targetNode = node.expression;
    final message = _generator.generate(
      typeLabel: 'Throw',
      name: 'Exception',
      path: resolver.path,
      dartType: targetNode.staticType,
    );
    _reporter.reportOnNode(targetNode, message);
  }

  void _onMethodInvocation(MethodInvocation node) {
    final targetNode = node.methodName;
    final message = _generator.generate(
      typeLabel: 'Invocation',
      name: targetNode.name,
      path: resolver.path,
      dartType: node.staticType,
      element: targetNode.element,
    );
    _reporter.reportOnNode(targetNode, message);
  }

  void _onInstanceCreation(InstanceCreationExpression node) {
    final targetNode = node.constructorName;
    final message = _generator.generate(
      typeLabel: 'Instantiation',
      name: targetNode.toSource(),
      path: resolver.path,
      dartType: node.staticType,
      element: targetNode.name?.element,
    );
    _reporter.reportOnNode(targetNode, message);
  }
}
