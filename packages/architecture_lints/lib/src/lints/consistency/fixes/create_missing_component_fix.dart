/*import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/generation/template_engine.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/consistency/logic/relationship_logic.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class CreateMissingComponentFix extends DartFix with NamingLogic, RelationshipLogic  {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    final config = context.sharedState[ArchitectureConfig] as ArchitectureConfig?;
    final fileResolver = context.sharedState[FileResolver] as FileResolver?;
    if (config == null || fileResolver == null) return;

    resolver.getResolvedUnitResult().then((unit) {
      AstNode? node;
      for (final declaration in unit.unit.declarations) {
        if (declaration.offset <= analysisError.offset &&
            declaration.end >= analysisError.offset + analysisError.length) {
          node = declaration;
          break;
        }
      }

      if (node == null) return;

      final component = fileResolver.resolve(resolver.path);
      if (component == null) return;

      // Re-calculate target on fix invocation
      final target = findMissingTarget(
        node: node,
        config: config,
        currentComponent: component,
        fileResolver: fileResolver,
        currentFilePath: resolver.path,
      );

      if (target == null || target.templateId == null) return;

      final template = config.templates[target.templateId];
      if (template == null) return;

      final content = TemplateEngine.render(template.toString(), target.coreName);

      final changeBuilder =
          reporter.createChangeBuilder(
            message: 'Create missing file: ${target.targetClassName}',
            priority: 100,
          )..addGenericFileEdit((builder) {
            builder.addSimpleInsertion(0, content);
          }, customPath: target.path);
    });
  }
}*/
