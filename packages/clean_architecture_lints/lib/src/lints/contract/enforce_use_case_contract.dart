// lib/src/lints/contracts/enforce_use_case_contract.dart

import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/rules/inheritance_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceUseCaseContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_use_case_contract',
    problemMessage: 'UseCases must implement one of the base use case classes: {0}.',
  );

  // Hardcoded defaults for the core architectural contract.
  static const _defaultUnaryName = 'UnaryUsecase';
  static const _defaultNullaryName = 'NullaryUsecase';
  static const _defaultPath = 'package:clean_architecture_core/usecase/usecase.dart';

  const EnforceUseCaseContract({required super.config, required super.layerResolver})
    : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.usecase) return;

    // If the user has defined a custom rule for 'use_case', let the generic lint handle it.
    final userRule = config.inheritance.rules.firstWhereOrNull((r) => r.on == 'use_case');
    if (userRule != null) return;

    // If no custom rule, use our hardcoded defaults.
    final requiredDetails = [
      const InheritanceDetail(name: _defaultUnaryName, import: _defaultPath),
      const InheritanceDetail(name: _defaultNullaryName, import: _defaultPath),
    ];

    final requiredNames = requiredDetails.map((d) => d.name).toSet();
    final requiredUris = requiredDetails.map((d) => _buildExpectedUri(d.import, context)).toSet();

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        return requiredNames.contains(superElement.name) &&
            requiredUris.contains(superElement.library.uri.toString());
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: [requiredNames.join(' or ')]);
      }
    });
  }

  String _buildExpectedUri(String configPath, CustomLintContext context) {
    if (configPath.startsWith('package:')) return configPath;
    final packageName = context.pubspec.name;
    final sanitizedPath = configPath.startsWith('/') ? configPath.substring(1) : configPath;
    return 'package:$packageName/$sanitizedPath';
  }
}
