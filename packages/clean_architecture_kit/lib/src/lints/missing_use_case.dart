// lib/src/lints/missing_use_case.dart
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/fixes/create_use_case_fix.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:clean_architecture_kit/src/utils/path_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MissingUseCase extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'missing_use_case',
    problemMessage: 'The repository method `{0}` is missing a corresponding `{1}` UseCase.',
    correctionMessage: 'Create a UseCase to encapsulate this business logic.',
  );

  const MissingUseCase({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  List<Fix> getFixes() => [CreateUseCaseFix(config: config)];

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.domainRepository) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword == null) return;

      for (final member in node.members) {
        // Rule only applies to public methods.
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

  /// Checks a single method and reports an error if its use case is missing.
  void _checkMethodForMissingUseCase({
    required MethodDeclaration method,
    required String repoPath,
    required DiagnosticReporter reporter,
  }) {
    final methodName = method.name.lexeme;

    // Use the robust utility to determine the expected file path.
    final expectedFilePath = PathUtils.getUseCaseFilePath(
      methodName: methodName,
      repoPath: repoPath,
      config: config,
    );

    if (expectedFilePath != null) {
      // The File IO check is necessary here. Caching can be added later if performance becomes an
      // issue.
      final file = File(expectedFilePath);
      if (!file.existsSync()) {
        final expectedClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);

        // Provide a more helpful, dynamic message.
        reporter.atToken(
          method.name,
          LintCode(
            name: _code.name,
            problemMessage:
                'The repository method `$methodName` is missing the corresponding '
                '`$expectedClassName` UseCase.',
            correctionMessage: 'Press 💡 to generate the UseCase file automatically.',
            errorSeverity: _code.errorSeverity,
          ),
        );
      }
    }
  }
}
