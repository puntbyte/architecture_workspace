import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that ensures calls to a DataSource within a repository are wrapped in a try-catch block.
class EnforceTryCatchInRepository extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_try_catch_in_repository',
    problemMessage: 'Calls to a DataSource must be wrapped in a `try` block.',
    correctionMessage: 'Wrap this call in a try-catch block and return a Failure on error.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceTryCatchInRepository({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // 1. Scope: Only runs on Repository Implementations
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    context.registry.addMethodInvocation((node) {
      // 2. Identify Target: Check the type of the object being called
      final targetType = node.target?.staticType ?? node.realTarget?.staticType;
      if (targetType == null) return;

      final element = targetType.element;
      if (element == null) return;

      // 3. Identify Origin: Where is this type defined?
      // [Analyzer 8.0.0 Fix] Use firstFragment.source
      final source = element.library?.firstFragment.source;
      if (source == null) return;

      final targetComponent = layerResolver.getComponent(source.fullName);

      // 4. Check Component: Is the target a DataSource?
      final isDataSource = targetComponent == ArchComponent.sourceInterface ||
          targetComponent == ArchComponent.sourceImplementation ||
          targetComponent == ArchComponent.source;

      if (isDataSource) {
        // 5. Safety Check: Is it inside a try block?
        if (!_isInsideTryBlock(node)) {
          reporter.atNode(node, _code);
        }
      }
    });
  }

  /// Checks if [node] is a descendant of the `body` of a [TryStatement].
  bool _isInsideTryBlock(MethodInvocation node) {
    final tryStatement = node.thisOrAncestorOfType<TryStatement>();
    if (tryStatement == null) return false;

    // The call must be inside the `try { ... }` block, not `catch` or `finally`.
    final tryBody = tryStatement.body;
    return node.offset >= tryBody.offset && node.end <= tryBody.end;
  }
}
