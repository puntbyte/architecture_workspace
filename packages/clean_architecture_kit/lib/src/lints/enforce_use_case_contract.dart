// lib/src/lints/enforce_use_case_contract.dart
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceUseCaseContract extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_use_case_contract',
    problemMessage: 'UseCases must fulfill a base use case contract by implementing {0}.',
    correctionMessage:
        'Add `implements UnaryUsecase<...>` or `implements NullaryUsecase<...>` to the class '
        'definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceUseCaseContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.useCase) return;

    final inheritanceConfig = config.inheritance;
    final unaryName = inheritanceConfig.unaryUseCaseName;
    final nullaryName = inheritanceConfig.nullaryUseCaseName;

    String buildExpectedUri(String configPath) {
      if (configPath.startsWith('package:')) return configPath;

      final packageName = context.pubspec.name;
      final sanitizedPath = configPath.startsWith('/') ? configPath.substring(1) : configPath;
      return 'package:$packageName/$sanitizedPath';
    }

    final expectedUnaryUri = buildExpectedUri(inheritanceConfig.unaryUseCasePath);
    final expectedNullaryUri = buildExpectedUri(inheritanceConfig.nullaryUseCasePath);

    if (unaryName.isEmpty || nullaryName.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;

      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        final libraryUriString = superElement.library.uri.toString();

        final isUnary = superElement.name == unaryName && libraryUriString == expectedUnaryUri;
        final isNullary =
            superElement.name == nullaryName && libraryUriString == expectedNullaryUri;

        return isUnary || isNullary;
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [[unaryName, nullaryName].join(' or ')],
        );
      }
    });
  }
}
