// lib/src/lints/purity/disallow_model_return_from_repository.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowModelReturnFromRepository extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_model_return_from_repository',
    problemMessage: 'Repository methods must return domain Entities, not data Models.',
    correctionMessage: 'Map the Model to an Entity before returning it from the repository.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  /// A cached set of wrapper type names for efficiency.
  late final Set<String> _wrapperTypeNames = {
    // Get the types from the central config.
    ...config.typeSafety.returns.map((rule) => rule.type),
    // Also include common implementation wrappers.
    'Right',
  };

  DisallowModelReturnFromRepository({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataRepository) return;

    // This lint now focuses solely on the implementation detail of the return statement,
    // which is its most valuable and unique contribution.
    context.registry.addReturnStatement((node) {
      final expression = node.expression;
      if (expression == null) return;

      final parentMethod = node.thisOrAncestorOfType<MethodDeclaration>();
      final methodElement = parentMethod?.declaredFragment?.element;
      if (methodElement == null || methodElement.isPrivate) return;

      if (SemanticUtils.isArchitecturalOverride(methodElement, layerResolver)) {
        final successType = _extractSuccessType(expression.staticType);
        if (SemanticUtils.isModelType(successType, layerResolver)) {
          reporter.atNode(expression, _code);
        }
      }
    });
  }

  /// Recursively unwraps a type to find the core "success" type.
  /// This now uses the centrally configured wrapper types.
  DartType? _extractSuccessType(DartType? type) {
    if (type is! InterfaceType) return type;

    // THE IMPROVEMENT IS HERE: Use the cached set from the config.
    if (_wrapperTypeNames.contains(type.element.name)) {
      if (type.typeArguments.isEmpty) return null;
      // Recurse on the last type argument.
      return _extractSuccessType(type.typeArguments.last);
    }

    return type;
  }
}
