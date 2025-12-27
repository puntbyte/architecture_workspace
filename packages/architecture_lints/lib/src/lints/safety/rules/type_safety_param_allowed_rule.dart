import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/engines/resolution/type_resolver.dart';
import 'package:architecture_lints/src/lints/safety/base/type_safety_base_rule.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/policies/type_safety_policy.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class TypeSafetyParamAllowedRule extends TypeSafetyBaseRule {
  static const _code = LintCode(
    name: 'arch_safety_param_strict',
    problemMessage: 'Invalid Parameter Type: "{0}" is not allowed for "{1}".',
    correctionMessage: 'Use one of the allowed types: {2}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const TypeSafetyParamAllowedRule() : super(code: _code);

  @override
  void checkParameter({
    required FormalParameter node,
    required DartType type,
    required String paramName,
    required List<TypeSafetyPolicy> rules,
    required ArchitectureConfig config,
    required TypeResolver typeResolver,
    required DiagnosticReporter reporter,
  }) {
    for (final rule in rules) {
      final allowed = rule.allowed
          .where((c) => matchesParameterName(c, paramName))
          .toList();

      if (allowed.isEmpty) continue;

      final matchesAny = allowed.any(
        (c) => matchesConstraint(type, c, typeResolver),
      );

      if (!matchesAny) {
        final isForbidden = isExplicitlyForbidden(
          type: type,
          configRule: rule,
          kind: 'parameter',
          paramName: paramName,
          typeResolver: typeResolver,
        );

        if (isForbidden) continue;

        final description = allowed
            .map((c) => describeConstraint(c, config.definitions))
            .join(', ');

        AstNode? highlightNode;
        if (node is SimpleFormalParameter) {
          highlightNode = node.type;
        } else if (node is FieldFormalParameter) {
          highlightNode = node.type;
        } else if (node is SuperFormalParameter) {
          highlightNode = node.type;
        }

        if (highlightNode != null) {
          reporter.atNode(
            highlightNode,
            _code,
            arguments: [type.getDisplayString(), paramName, description],
          );
        } else if (node.name != null) {
          reporter.atToken(
            node.name!,
            _code,
            arguments: [type.getDisplayString(), paramName, description],
          );
        } else {
          reporter.atNode(
            node,
            _code,
            arguments: [type.getDisplayString(), paramName, description],
          );
        }
      }
    }
  }
}
