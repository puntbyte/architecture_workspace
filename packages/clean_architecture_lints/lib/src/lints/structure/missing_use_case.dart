// lib/src/lints/missing_use_case.dart

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/fixes/create_use_case_fix.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:clean_architecture_lints/src/utils/path_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that identifies public methods in a repository contract that do not
/// have a corresponding `UseCase` file.
///
/// **Reasoning:** In a strict Clean Architecture, every piece of business logic
/// should be encapsulated in its own UseCase. This lint helps enforce that rule

/// by scanning repository interfaces and flagging methods that represent
/// un-encapsulated business operations. It provides a powerful quick fix to
/// generate the boilerplate for the missing UseCase.
class MissingUseCase extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'missing_use_case',
    problemMessage: 'The repository method `{0}` is missing a corresponding UseCase file.',
    correctionMessage: 'Consider creating a UseCase for this business logic.',
  );

  const MissingUseCase({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  /// Provides the `CreateUseCaseFix` to generate the missing file.
  @override
  List<Fix> getFixes() => [CreateUseCaseFix(config: config)];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // This generative lint specifically targets repository interfaces (contracts).
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.contract) return;

    context.registry.addClassDeclaration((node) {
      // The rule only applies to the abstract interface definition.
      if (node.abstractKeyword == null) return;

      for (final member in node.members) {
        // We only care about public, concrete methods (not getters, setters, or private methods).
        if (member is MethodDeclaration &&
            !member.isGetter &&
            !member.isSetter &&
            !member.name.lexeme.startsWith('_')) {
          _checkMethodForMissingUseCase(
            method: member,
            repoPath: resolver.source.fullName,
            reporter: reporter,
          );
        }
      }
    });
  }

  /// Checks a single method and reports an error if its corresponding use case file is missing.
  void _checkMethodForMissingUseCase({
    required MethodDeclaration method,
    required String repoPath,
    required DiagnosticReporter reporter,
  }) {
    final methodName = method.name.lexeme;

    // Use the robust PathUtils to determine the expected absolute file path for the use case.
    final expectedFilePath = PathUtils.getUseCaseFilePath(
      methodName: methodName,
      repoPath: repoPath,
      config: config,
    );

    if (expectedFilePath != null) {
      // This is a necessary file system check to see if the file has been created.
      final file = File(expectedFilePath);
      if (!file.existsSync()) {
        final expectedClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);

        // Report a dynamic, helpful error message that includes the specific names.
        reporter.atToken(
          method.name,
          LintCode(
            name: _code.name,
            problemMessage:
                'The repository method `$methodName` is missing the corresponding '
                    '`$expectedClassName` UseCase.',
            correctionMessage: 'Press 💡 to generate the UseCase file automatically.',
          ),
        );
      }
    }
  }
}
