import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:architecture_lints/src/actions/code_generator.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/actions/logic/mustache_renderer.dart';
import 'package:architecture_lints/src/actions/logic/template_loader.dart';
import 'package:architecture_lints/src/config/parsing/config_loader.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

class ArchitectureFix extends DartFix {
  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    // PRE-LOAD EVERYTHING ASYNC HERE
    try {
      if (!context.sharedState.containsKey(ArchitectureConfig)) {
        final config = await ConfigLoader.loadFromContext(resolver.path);
        if (config != null) context.sharedState[ArchitectureConfig] = config;
      }
      // CRITICAL: Pre-load the ResolvedUnitResult so we can use it synchronously in run()
      if (!context.sharedState.containsKey(ResolvedUnitResult)) {
        final unit = await resolver.getResolvedUnitResult();
        context.sharedState[ResolvedUnitResult] = unit;
      }
    } catch (e) {
      // Swallow startup errors (linter shouldn't crash)
    }
    await super.startUp(resolver, context);
  }

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    // Wraps the logic in try-catch to prevent crashing the plugin on logic errors
    try {
      protectedRun(resolver, reporter, context, analysisError);
    } catch (e) {
      // print('ArchitectureFix Error: $e');
    }
  }

  @visibleForTesting
  void protectedRun(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
  ) {
    // 1. Retrieve Pre-loaded Data
    final config = context.sharedState[ArchitectureConfig] as ArchitectureConfig?;
    final unitResult = context.sharedState[ResolvedUnitResult] as ResolvedUnitResult?;

    if (config == null || unitResult == null) return;

    // 2. Match Action
    final errorCode = analysisError.errorCode.name;
    final actions = config.getActionsForError(errorCode);

    if (actions.isEmpty) return;

    // 3. Setup Tools
    final rootPath = ConfigLoader.findRootPath(resolver.path) ?? p.dirname(resolver.path);
    final loader = TemplateLoader(rootPath);
    final generator = CodeGenerator(config, loader, context.pubspec.name);
    const renderer = MustacheRenderer();

    // 4. Find AST Node
    var errorNode = _findNodeAt(unitResult.unit, analysisError.offset);

    // Walk up to find a declaration (Method or Class)
    while (errorNode != null) {
      if (errorNode is MethodDeclaration || errorNode is ClassDeclaration) break;
      errorNode = errorNode.parent;
    }
    errorNode ??= unitResult.unit.declarations.firstOrNull ?? unitResult.unit;

    // 5. Execute
    final variableResolver = VariableResolver(
      sourceNode: errorNode,
      config: config,
      packageName: context.pubspec.name,
    );

    for (final action in actions) {
      // A. Generate Code
      final code = generator.generate(action: action, sourceNode: errorNode);
      if (code == null) continue;

      // B. Resolve Filename
      String? targetPath;
      if (action.target.filename.isNotEmpty) {
        final templateContext = variableResolver.resolveMap(action.variables);

        // Evaluate simple expressions in filename (e.g. ${snakeCase})
        // Note: VariableResolver.resolve works on single expressions
        final resolvedFilename = action.target.filename.replaceAllMapped(RegExp(r'\$\{(.*?)\}'), (
          match,
        ) {
          final expr = match.group(1);
          return expr != null ? variableResolver.resolve(expr).toString() : match.group(0)!;
        });

        // Render Mustache (if any)
        final fileName = renderer.render(resolvedFilename, templateContext);

        final currentDir = p.dirname(resolver.path);
        targetPath = p.normalize(p.join(currentDir, action.target.directory, fileName));
      }

      // C. Report Change
      final changeBuilder = reporter.createChangeBuilder(
        message: action.description,
        priority: 100,
      );

      changeBuilder.addDartFileEdit((builder) {
        if (targetPath != null && targetPath != resolver.path) {
          // New file content
          builder.addSimpleReplacement(SourceRange(0, 0), code);
        } else {
          // Append to current file
          builder.addSimpleInsertion(unitResult.unit.end, '\n$code');
        }
      }, customPath: targetPath);
    }
  }

  /// Helper to safely find node at offset
  AstNode? _findNodeAt(CompilationUnit unit, int offset) {
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
        return currentNode;
      }
    }
  }
}
