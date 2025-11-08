// lib/srcs/lints/enforce_type_safety.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/type_safety_config.dart';
import 'package:clean_architecture_kit/src/utils/ast_utils.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/string_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceTypeSafety extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_type_safety',
    problemMessage: 'Architectural type safety violation: This signature is incorrect.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceTypeSafety({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer == ArchSubLayer.unknown) return;

    final subLayerNameSnakeCase = subLayer.name.toSnakeCase();

    final applicableReturnRules = config.typeSafety.returns
        .where((rule) => rule.where.contains(subLayerNameSnakeCase))
        .toList();

    final applicableParamRules = config.typeSafety.parameters
        .where((rule) => rule.where.contains(subLayerNameSnakeCase))
        .toList();

    if (applicableReturnRules.isEmpty && applicableParamRules.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      for (final rule in applicableReturnRules) {
        _validateReturnType(node, rule, reporter);
      }

      for (final rule in applicableParamRules) {
        _validateParameters(node, rule, reporter);
      }
    });
  }

  void _validateReturnType(MethodDeclaration node, ReturnRule rule, DiagnosticReporter reporter) {
    // NEW: skip syntactic setters so parser-only tests (no resolution) don't treat setters as methods.
    if (node.isSetter) return;

    final element = node.declaredFragment?.element;
    if (element is ConstructorElement || element is SetterElement) return;

    final returnTypeNode = node.returnType;
    if (returnTypeNode == null) {
      reporter.atToken(
        node.name,
        LintCode(
          name: _code.name,
          problemMessage: 'Methods in this layer must have a return type of `${rule.type}`.',
        ),
      );

      return;
    }

    final returnTypeSource = returnTypeNode.toSource();
    if (!returnTypeSource.startsWith(rule.type)) {
      reporter.atNode(
        returnTypeNode,
        LintCode(
          name: _code.name,
          problemMessage: 'The return type must be `${rule.type}`, but found `$returnTypeSource`.',
        ),
      );
    }
  }


  void _validateParameters(
    MethodDeclaration node,
    ParameterRule rule,
    DiagnosticReporter reporter,
  ) {
    for (final parameter in node.parameters?.parameters ?? <FormalParameter>[]) {
      final paramName = parameter.name?.lexeme;
      final typeNode = AstUtils.getParameterTypeNode(parameter);
      if (paramName == null || typeNode == null) continue;

      if (rule.identifier != null) {
        if (!paramName.toLowerCase().contains(rule.identifier!.toLowerCase())) continue;
      }

      final typeSource = typeNode.toSource();
      if (!typeSource.startsWith(rule.type)) {
        reporter.atNode(
          typeNode,
          LintCode(
            name: _code.name,
            problemMessage:
                'Parameters identified by `${rule.identifier ?? ''}` must be of type '
                '`${rule.type}`, but found `$typeSource`.',
          ),
        );
      }
    }
  }
}
