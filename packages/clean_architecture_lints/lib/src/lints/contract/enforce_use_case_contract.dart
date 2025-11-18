// lib/src/lints/contract/enforce_use_case_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that concrete UseCase classes implement one of the base UseCase classes.
class EnforceUseCaseContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_use_case_contract',
    problemMessage: 'UseCases must extend one of the base use case classes: {0}.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _defaultBaseNames = {'UnaryUsecase', 'NullaryUsecase'};
  static const _defaultCorePackagePath =
      'package:clean_architecture_core/clean_architecture_core.dart';

  final bool _isIgnored;

  EnforceUseCaseContract({required super.config, required super.layerResolver})
    : _isIgnored = config.inheritances.rules.any((r) => r.on == ArchComponent.usecase.id),
      super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (_isIgnored) return;
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.usecase) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return; // Only check concrete implementations

      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      final expectedLocalUri = 'package:${context.pubspec.name}/core/usecase/usecase.dart';

      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        final libraryUri = superElement.library.firstFragment.source.uri.toString();

        return _defaultBaseNames.contains(superElement.name) &&
            (libraryUri == _defaultCorePackagePath || libraryUri == expectedLocalUri);
      });

      if (!hasCorrectSupertype) {
        final expectedNames = _defaultBaseNames.join(' or ');
        reporter.atToken(node.name, _code, arguments: [expectedNames]);
      }
    });
  }
}
