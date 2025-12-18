import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:architecture_lints/src/schema/definitions/action_definition.dart';
import 'package:architecture_lints/src/schema/enums/write_placement.dart';
import 'package:architecture_lints/src/schema/enums/write_strategy.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EditApplicator {
  void apply({
    required ChangeReporter reporter,
    required ActionDefinition action,
    required String code,
    required String? targetPath,
    required String currentPath,
    required AstNode sourceNode,
    required ResolvedUnitResult unitResult,
  }) {
    final changeBuilder = reporter.createChangeBuilder(
      message: action.description,
      priority: 100,
    );

    // If writing to a file, use targetPath, otherwise use current path
    final editPath = (action.write.strategy == WriteStrategy.file && targetPath != null)
        ? targetPath
        : currentPath;

    changeBuilder.addDartFileEdit((builder) {
      switch (action.write.strategy) {
        case WriteStrategy.file:
          _applyFileEdit(builder, code, targetPath, currentPath, unitResult);
        case WriteStrategy.inject:
          _applyInjectionEdit(builder, code, sourceNode, action.write.placement);
        case WriteStrategy.replace:
          builder.addReplacement(
            SourceRange(sourceNode.offset, sourceNode.length),
                (b) => b.write(code),
          );
      }
    }, customPath: editPath);
  }

  void _applyFileEdit(
      DartFileEditBuilder builder,
      String code,
      String? targetPath,
      String currentPath,
      ResolvedUnitResult unitResult,
      ) {
    if (targetPath != null && targetPath != currentPath) {
      // Creating/Overwriting NEW file
      builder.addSimpleReplacement(SourceRange(0, 0), code);
    } else {
      // Appending to CURRENT file
      builder.addSimpleInsertion(unitResult.unit.end, '\n$code');
    }
  }

  void _applyInjectionEdit(
      DartFileEditBuilder builder,
      String code,
      AstNode sourceNode,
      WritePlacement placement,
      ) {
    final classNode = sourceNode.thisOrAncestorOfType<ClassDeclaration>();

    int offset;
    if (classNode != null) {
      if (placement == WritePlacement.end) {
        offset = classNode.rightBracket.offset;
      } else {
        offset = classNode.leftBracket.end;
      }
    } else {
      offset = sourceNode.end;
    }

    builder.addSimpleInsertion(offset, '\n$code');
  }
}