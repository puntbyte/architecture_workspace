// lib/src/lints/contract/enforce_repository_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceRepositoryContract extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_repository_contract',
    problemMessage:
        'Repository interfaces must fulfill the base repository contract by implementing `{0}`.',
    correctionMessage: 'Add `implements {0}` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceRepositoryContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.domainRepository) return;

    final baseClassName = config.inheritance.repositoryBaseName;
    final basePath = config.inheritance.repositoryBasePath;
    if (baseClassName.isEmpty || basePath.isEmpty) return;

    final String expectedPackageUri;
    if (basePath.startsWith('package:')) {
      expectedPackageUri = basePath;
    } else {
      final packageName = context.pubspec.name;
      final sanitizedPath = basePath.startsWith('/') ? basePath.substring(1) : basePath;
      expectedPackageUri = 'package:$packageName/$sanitizedPath';
    }

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword == null) return;

      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        return superElement.name == baseClassName &&
            superElement.library.uri.toString() == expectedPackageUri;
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: [baseClassName]);
      }
    });
  }
}
