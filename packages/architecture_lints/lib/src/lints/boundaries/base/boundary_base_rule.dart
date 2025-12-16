import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/engines/imports/import_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class BoundaryBaseRule extends ArchitectureRule {
  const BoundaryBaseRule({required super.code});

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    // 1. Check Imports
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;

      final importedPath = ImportResolver.resolvePath(node: node);

      checkImport(
        node: node,
        uri: uri,
        importedPath: importedPath,
        config: config,
        fileResolver: fileResolver,
        component: component,
        reporter: reporter,
        resolver: resolver,
        context: context, // Pass context here
      );
    });

    // 2. Check Usages
    context.registry.addNamedType((node) {
      checkUsage(
        node: node,
        config: config,
        fileResolver: fileResolver,
        component: component,
        reporter: reporter,
        resolver: resolver,
        context: context, // Pass context here
      );
    });
  }

  /// Called for every import directive.
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
  });

  /// Called for every named type usage.
  void checkUsage({
    required NamedType node,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required ComponentContext? component,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required CustomLintContext context,
  }) {}
}
