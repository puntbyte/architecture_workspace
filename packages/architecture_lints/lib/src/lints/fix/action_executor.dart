import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/engines/file/file.dart';
import 'package:architecture_lints/src/engines/generator/code_generator.dart';
import 'package:architecture_lints/src/engines/variable/variable.dart';
import 'package:architecture_lints/src/lints/fix/edit_applicator.dart';
import 'package:architecture_lints/src/lints/fix/target_resolver.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/action_definition.dart';
import 'package:architecture_lints/src/schema/enums/action_scope.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ActionExecutor {
  final CodeGenerator generator;
  final RelatedFileResolver relatedResolver;
  final TargetResolver targetResolver;
  final EditApplicator editApplicator;

  ActionExecutor({
    required ArchitectureConfig config,
    required this.generator,
  }) : relatedResolver = RelatedFileResolver(config),
       targetResolver = TargetResolver(config: config),
       editApplicator = EditApplicator();

  Future<void> execute({
    required ActionDefinition action,
    required AstNode sourceNode,
    required String sourceFilePath,
    required ArchitectureConfig config,
    required String packageName,
    required CustomLintResolver resolver,
    required ResolvedUnitResult unitResult,
    required ChangeReporter reporter,
    required ComponentContext? currentContext, // FIX: Made nullable
  }) async {
    var effectiveSourceNode = sourceNode;

    // 1. Handle Context Switching
    if (action.source.scope == ActionScope.related && action.source.component != null) {
      if (currentContext != null) {
        final relatedResult = await relatedResolver.resolveRelated(
          currentContext: currentContext,
          targetComponentId: action.source.component!,
          session: unitResult.session,
        );

        if (relatedResult != null && relatedResult.exists) {
          final mainClass = relatedResult.unit.declarations
              .whereType<ClassDeclaration>()
              .firstOrNull;
          effectiveSourceNode = mainClass ?? relatedResult.unit;
        } else {
          return;
        }
      }
    }

    // 2. Generate Code
    // FIX: Removed session and sourceFilePath arguments
    final code = await generator.generate(
      action: action,
      sourceNode: effectiveSourceNode,
    );

    if (code == null) return;

    // 3. Resolve Target Path
    String? targetPath;
    if (action.write.filename != null && action.write.filename!.isNotEmpty) {
      final varResolver = VariableResolver(
        sourceNode: effectiveSourceNode,
        config: config,
        packageName: packageName,
      );

      targetPath = targetResolver.resolvePath(
        action: action,
        variableResolver: varResolver,
        currentPath: resolver.path,
      );
    }

    // 4. Apply Edit
    editApplicator.apply(
      reporter: reporter,
      action: action,
      code: code,
      targetPath: targetPath,
      currentPath: resolver.path,
      sourceNode: sourceNode,
      unitResult: unitResult,
    );
  }
}
