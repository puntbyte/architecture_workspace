import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/domain/module_context.dart';
import 'package:architecture_lints/src/lints/boundaries/base/boundary_base_rule.dart';
import 'package:architecture_lints/src/lints/boundaries/logic/module_logic.dart'; // Ensure Mixin is imported
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ModuleDependencyRule extends BoundaryBaseRule with ModuleLogic {
  static const _code = LintCode(
    name: 'arch_dep_module',
    problemMessage: 'Module Isolation Violation: {0} "{1}" cannot import {0} "{2}".',
    correctionMessage: 'Sibling modules must remain independent. Use a shared module.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ModuleDependencyRule() : super(code: _code);

  @override
  void checkImport({
    required ImportDirective node,
    required String uri,
    required String? importedPath,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required ComponentContext? component,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required CustomLintContext context,
  }) {
    _check(
      node: node.uri,
      importedPath: importedPath,
      resolver: resolver,
      config: config,
      fileResolver: fileResolver,
      component: component,
      reporter: reporter,
    );
  }

  void _check({
    required AstNode node,
    required String? importedPath,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required ComponentContext? component,
    required DiagnosticReporter reporter,
  }) {
    if (importedPath == null) return;

    // 1. Identify Current Module
    var currentModule = component?.module;

    // FIX: Use resolveModuleContext (name from ModuleLogic mixin)
    currentModule ??= resolveModuleContext(resolver.path, config.modules);

    if (currentModule == null || !currentModule.isStrict) return;

    // 2. Identify Imported Module
    final importedComponent = fileResolver.resolve(importedPath);
    var importedModule = importedComponent?.module;

    // FIX: Use resolveModuleContext
    importedModule ??= resolveModuleContext(importedPath, config.modules);

    if (importedModule == null) return;

    // 3. Check Isolation
    if (!currentModule.canImport(importedModule)) {
      final typeName = currentModule.key.replaceFirstMapped(
        RegExp('^[a-z]'),
        (m) => m.group(0)!.toUpperCase(),
      );

      reporter.atNode(
        node,
        _code,
        arguments: [
          typeName,
          currentModule.name,
          importedModule.name,
        ],
      );
    }
  }
}
