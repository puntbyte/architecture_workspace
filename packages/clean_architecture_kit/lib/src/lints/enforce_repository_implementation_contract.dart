// lib/src/lints/enforce_repository_implementation_contract.dart
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceRepositoryImplementationContract extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_repository_implementation_contract',
    problemMessage:
        'Repository implementations must implement their corresponding repository interface from '
        'the domain layer.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceRepositoryImplementationContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataRepository) return;

    context.registry.addClassDeclaration((node) {
      final classElement = node.declaredFragment?.element;
      if (classElement == null || classElement.isAbstract) return;

      final hasRepoInterface = classElement.allSupertypes.any((supertype) {
        final source = supertype.element.firstFragment.libraryFragment.source;
        return layerResolver.getSubLayer(source.fullName) == ArchSubLayer.domainRepository;
      });

      if (!hasRepoInterface) {
        reporter.atToken(node.name, _code);
      }
    });
  }
}
