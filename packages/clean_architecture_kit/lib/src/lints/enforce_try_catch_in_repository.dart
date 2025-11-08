import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceTryCatchInRepository extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_try_catch_in_repository',
    problemMessage: 'Calls to a DataSource must be wrapped in a try-catch block.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceTryCatchInRepository({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataRepository) return;

    context.registry.addMethodInvocation((node) {
      final targetType = node.target?.staticType;
      if (targetType == null) return;

      final source = targetType.element?.firstFragment.libraryFragment?.source;
      if (source == null) return;

      // Is this a call on a DataSource?
      if (layerResolver.getSubLayer(source.fullName) == ArchSubLayer.dataSource) {
        // Is it inside a try block?
        if (node.thisOrAncestorOfType<TryStatement>() == null) {
          reporter.atNode(node, _code);
        }
      }
    });
  }
}
