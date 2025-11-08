// lib/src/lints/enforce_exception_on_data_source.dart
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceExceptionOnDataSource extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_exception_on_data_source',
    problemMessage: 'DataSources should throw exceptions on failure, not return wrapper types like Either/Result.',
    correctionMessage: 'Change the return type to a simple Future and throw a specific Exception on failure.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceExceptionOnDataSource({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataSource) return;

    // Get the list of "special" return types from the central config.
    final forbiddenReturnTypes = config.typeSafety.returns
        .map((rule) => rule.type)
        .toSet();

    if (forbiddenReturnTypes.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      final returnTypeNode = node.returnType;
      if (returnTypeNode == null) return;

      final returnTypeName = returnTypeNode.toSource().split('<').first;

      // The violation is simple: does the return type match one of the forbidden types?
      if (forbiddenReturnTypes.contains(returnTypeName)) {
        reporter.atNode(returnTypeNode, _code);
      }
    });
  }
}
