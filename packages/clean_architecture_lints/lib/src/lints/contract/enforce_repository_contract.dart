// lib/src/lints/contracts/enforce_repository_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceRepositoryContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_repository_contract',
    problemMessage: 'Repository interfaces must implement the base repository class `{0}`.',
    correctionMessage: 'Add `implements {0}` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  // Hardcoded default for the core architectural contract.
  static const _defaultBaseName = 'Repository';
  static const _defaultBasePath = 'package:clean_architecture_core/repository/repository.dart';

  const EnforceRepositoryContract({required super.config, required super.layerResolver})
    : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.contract) return;

    // --- LOGIC: Use user config as an OVERRIDE, otherwise use default ---
    final userRule = config.inheritance.rules.firstWhereOrNull((r) => r.on == 'contract');

    // If the user has defined a custom rule for 'contract', the generic `enforce_inheritance`
    // lint will handle it. This lint should stay silent to avoid duplicate warnings.
    if (userRule != null) return;

    final expectedPackageUri = _buildExpectedUri(_defaultBasePath, context);

    context.registry.addClassDeclaration((node) {
      // This core rule only applies to interfaces (abstract classes).
      if (node.abstractKeyword == null) return;
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        return superElement.name == _defaultBaseName &&
            superElement.library.uri.toString() == expectedPackageUri;
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: [_defaultBaseName]);
      }
    });
  }

  // This helper can be extracted to a shared utility file if desired.
  String _buildExpectedUri(String configPath, CustomLintContext context) {
    if (configPath.startsWith('package:')) return configPath;
    final packageName = context.pubspec.name;
    final sanitizedPath = configPath.startsWith('/') ? configPath.substring(1) : configPath;
    return 'package:$packageName/$sanitizedPath';
  }
}
