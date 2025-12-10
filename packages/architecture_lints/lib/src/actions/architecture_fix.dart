import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:architecture_lints/src/actions/context/source_wrapper.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/actions/generator.dart';
import 'package:architecture_lints/src/actions/logic/mustache_renderer.dart';
import 'package:architecture_lints/src/actions/logic/template_loader.dart';
import 'package:architecture_lints/src/config/parsing/config_loader.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

class ArchitectureFix extends DartFix {
  @override
  Future<void> run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError, // FIX: Use Diagnostic
    List<Diagnostic> others, // FIX: Use Diagnostic
  ) async {
    // 1. Load Config
    var config = context.sharedState[ArchitectureConfig] as ArchitectureConfig?;
    config ??= await ConfigLoader.loadFromContext(resolver.path);

    if (config == null) return;

    // 2. Find matching actions for this specific error
    final errorCode = analysisError.diagnosticCode.name;
    final actions = config.getActionsForError(errorCode);

    if (actions.isEmpty) return;

    // 3. Prepare Tools
    final rootPath = ConfigLoader.findRootPath(resolver.path) ?? p.dirname(resolver.path);
    final loader = TemplateLoader(rootPath);
    final generator = CodeGenerator(config, loader);
    const renderer = MustacheRenderer();

    // 4. Resolve AST Node for Context
    final result = await resolver.getResolvedUnitResult();

    // Find the node covering the error offset
    final errorNode = result.unit.declarations.firstWhere(
      (d) =>
          d.offset <= analysisError.offset && d.end >= analysisError.offset + analysisError.length,
      orElse: () => result.unit.declarations.first,
    );

    final sourceWrapper = SourceWrapper(errorNode);
    // FIX: Pass config to constructor
    final variableResolver = VariableResolver(sourceWrapper, config);

    // 5. Execute Actions
    for (final action in actions) {
      // A. Generate Code
      final code = await generator.generate(action: action, sourceNode: errorNode);
      if (code == null) continue;

      // B. Resolve Variables for Filename (if needed)
      final templateContext = variableResolver.resolveMap(action.variables);

      // C. Apply Change
      String? targetPath;

      if (action.target.filename.isNotEmpty) {
        // Resolve filename template (e.g. {{snakeCase}}.dart)
        final fileName = renderer.render(action.target.filename, templateContext);

        // Construct absolute path relative to current file
        final currentDir = p.dirname(resolver.path);
        // Combine: currentDir + ../usecases + filename.dart
        targetPath = p.normalize(p.join(currentDir, action.target.directory, fileName));
      }

      reporter
          .createChangeBuilder(
            message: action.description,
            priority: 100,
          )
          // FIX: Use named argument for customPath
          .addDartFileEdit((builder) {
            if (targetPath != null && targetPath != resolver.path) {
              // Creating/Editing a DIFFERENT file
              builder.addSimpleReplacement(
                SourceRange.EMPTY,
                // Insert at start (overwrite logic needed? usually safe for new files)
                code,
              );
            } else {
              // Editing CURRENT file
              builder.addSimpleInsertion(result.unit.end, '\n$code');
            }
          }, customPath: targetPath); // <--- Passed as named argument
    }
  }
}
