import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/engines/configuration/config_loader.dart';
import 'package:architecture_lints/src/engines/file/file.dart';
import 'package:architecture_lints/src/engines/generator/code_generator.dart';
import 'package:architecture_lints/src/engines/template/template_loader.dart';
import 'package:architecture_lints/src/lints/fix/action_executor.dart';
import 'package:architecture_lints/src/lints/fix/architecture_fix_base.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

class ArchitectureFix extends ArchitectureFixBase {
  @override
  Future<void> runProtected({
    required CustomLintResolver resolver,
    required ChangeReporter reporter,
    required CustomLintContext context,
    required Diagnostic analysisError,
    required ArchitectureConfig config, // Use ArchitectureConfig
    required ResolvedUnitResult unitResult,
  }) async {
    final errorCode = analysisError.errorCode.name;
    final actions = config.getActionsForError(errorCode);

    if (actions.isEmpty) return;

    // Tools
    final rootPath = ConfigLoader.findRootPath(resolver.path) ?? p.dirname(resolver.path);
    final loader = TemplateLoader(rootPath);
    final generator = CodeGenerator(config, loader, context.pubspec.name);
    final fileResolver = FileResolver(config);

    // Orchestrator
    final executor = ActionExecutor(config: config, generator: generator);

    // Context
    final currentContext = fileResolver.resolve(resolver.path);
    final errorNode = _findNodeAt(unitResult.unit, analysisError.offset);

    for (final action in actions) {
      if (action.trigger.component != null) {
        if (currentContext == null || !currentContext.matchesReference(action.trigger.component!)) {
          continue;
        }
      }

      await executor.execute(
        action: action,
        sourceNode: errorNode,
        sourceFilePath: resolver.path,
        config: config,
        packageName: context.pubspec.name,
        resolver: resolver,
        unitResult: unitResult,
        reporter: reporter,
        currentContext: currentContext, // Passes ComponentContext?
      );
    }
  }

  AstNode _findNodeAt(CompilationUnit unit, int offset) {
    var currentNode = unit as AstNode;
    while (true) {
      AstNode? childFound;
      for (final child in currentNode.childEntities) {
        if (child is AstNode) {
          if (child.offset <= offset && child.end >= offset) {
            childFound = child;
            break;
          }
        }
      }
      if (childFound != null) {
        currentNode = childFound;
      } else {
        // Walk up to find significant declaration
        while (currentNode is! MethodDeclaration &&
            currentNode is! ClassDeclaration &&
            currentNode is! FieldDeclaration &&
            currentNode.parent != null) {
          currentNode = currentNode.parent!;
        }
        return currentNode;
      }
    }
  }
}
