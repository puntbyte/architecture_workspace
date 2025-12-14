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

class DebugComponentIdentity extends ArchitectureLintRule with DebugComponentIdentityWrapper {
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
    // 1. Retrieve errors captured during startUp()
    final configError = context.sharedState['arch_config_error']?.toString();
    final refinerError = context.sharedState['arch_refiner_error']?.toString();
    final resolverError = context.sharedState['arch_resolver_error']?.toString();

    final combinedError = configError ?? refinerError ?? resolverError;

    DebugRuleRunner(
      context: context,
      reporter: reporter,
      resolver: resolver,
      config: config,
      fileResolver: fileResolver,
      component: component,
      globalError: combinedError, // Pass error down
    ).register();
  }
}

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
    this.globalError,
  }) {
    _reporter = ReporterHelper(reporter, DebugComponentIdentity._code);
    _generator = DebugReportGenerator(
      fileResolver: fileResolver,
      component: component,
      error: globalError,
    );
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

    // Additional Nodes
    //context.registry.addMethodDeclaration(_onMethodDeclaration);
    //context.registry.addVariableDeclaration(_onVariableDeclaration);
    //context.registry.addFormalParameter(_onFormalParameter);

    // 4) Type references
    context.registry.addNamedType(_onNamedType);

    // 5) Flow & logic
    context.registry.addReturnStatement(_onReturnStatement);
    context.registry.addThrowExpression(_onThrowExpression);
    //context.registry.addMethodInvocation(_onMethodInvocation);
    //context.registry.addInstanceCreationExpression(_onInstanceCreation);
  }

  // ----------------------------
  // Handlers
  // ----------------------------

  void _onCompilationUnit(CompilationUnit node) {
    final target = node.directives.firstOrNull ?? node.declarations.firstOrNull;
    if (target == null) return;

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
    // Prefer node.name, fallback to node itself
    _reporter.reportOnEntity(node.name ?? node, message);
  }

  void _onNamedType(NamedType node) {
    if (node.parent is ClassDeclaration ||
        node.parent is ConstructorDeclaration ||
        node.parent is MethodDeclaration ||
        node.parent is ExtendsClause ||
        node.parent is ImplementsClause ||
        node.parent is WithClause) {
      return;
    }

    final message = _generator.generate(
      typeLabel: 'Type Ref',
      name: node.name2.lexeme,
      path: resolver.path,
      dartType: node.type,
      element: node.element,
    );
    _reporter.reportOnToken(node.name2, message);
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
    final cName = node.constructorName;
    final element = cName.name?.element;

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

class DebugReportGenerator {
  final FileResolver fileResolver;
  final ComponentContext? component;
  final String? error;

  DebugReportGenerator({
    required this.fileResolver,
    required this.component,
    this.error,
  });

  String generateHeaderReport(String path) {
    final sb = StringBuffer();

    // ERROR HEADER
    if (error != null) {
      sb.writeln('🔥 FATAL CONFIGURATION / RUNTIME ERROR 🔥');
      sb.writeln(error);
      sb.writeln('==================================================\n');
    }

    sb.writeln('[DEBUG: FILE CONTEXT] "${path.split('/').last}"');
    sb.writeln('==================================================');

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

  String generate({
    required String typeLabel,
    required String name,
    required String path,
    DartType? dartType,
    Element? element,
    AstNode? astNode,
    String? extraInfo,
  }) {
    final sb = StringBuffer();

    // ERROR HEADER
    if (error != null) {
      sb.writeln('🔥 FATAL CONFIGURATION / RUNTIME ERROR 🔥');
      sb.writeln(error);
      sb.writeln('==================================================\n');
    }

    sb.writeln('[DEBUG: $typeLabel] "$name"');
    sb.writeln('==================================================');

    if (component != null) {
      sb.writeln('✅ RESOLVED: "${component!.id}"');
      if (component!.module != null) {
        sb.writeln('📦 Module:   "${component!.module!.key}"');
      }
      sb.writeln('📂 Mode:     ${component!.config.mode.name}');
    } else {
      sb.writeln('❌ RESOLVED: <NULL> (Orphan File)');
    }

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

    if (astNode is ClassDeclaration) {
      sb.writeln('\n🏗️ STRUCTURE:');
      final el = astNode.declaredFragment?.element;
      if (el != null) {
        sb..writeln('   • Abstract? ${el.isAbstract}')
        ..writeln('   • Interface? ${el.isInterface}')
        ..writeln('   • Sealed? ${el.isSealed}')
        ..writeln('   • Mixin Class? ${el.isMixinClass}');

        final supertypes = el.allSupertypes
            .map((t) => t.element.name)
            .whereType<String>()
            .where((n) => n != 'Object')
            .toList();

        sb.writeln('   • Hierarchy: ${_formatList(supertypes)}');
      }
    }

    if (component?.debugScoreLog != null) {
      sb.writeln('\n🧮 SCORING LOG:');
      sb.write(component!.debugScoreLog!.trimRight());
    }

    sb.writeln('\n==================================================');
    return sb.toString();
  }

  String _formatList(List<String> items) {
    if (items.isEmpty) return '[]';
    return '[ ${items.join(", ")} ]';
  }
}