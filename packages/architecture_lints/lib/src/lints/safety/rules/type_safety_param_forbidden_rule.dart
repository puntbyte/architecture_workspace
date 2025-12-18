import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/engines/resolution/type_resolver.dart';
import 'package:architecture_lints/src/lints/safety/base/type_safety_base_rule.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/policies/type_safety_policy.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class TypeSafetyParamForbiddenRule extends TypeSafetyBaseRule {
  static const _code = LintCode(
    name: 'arch_safety_param_forbidden',
    problemMessage: 'Invalid Parameter Type: "{0}" is forbidden for "{1}".{2}',
    correctionMessage: 'Change the parameter type.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const TypeSafetyParamForbiddenRule() : super(code: _code);

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
      final forbidden = rule.forbidden.where((c) => shouldCheckParam(c, paramName)).toList();
      final allowed = rule.allowed.where((c) => shouldCheckParam(c, paramName)).toList();

      if (forbidden.isEmpty) continue;

      // 1. Is it Forbidden?
      final isForbidden = matchesAnyConstraint(type, forbidden, typeResolver);

      if (isForbidden) {
        // 2. Is it Explicitly Allowed? (Override)
        final isAllowed = matchesAnyConstraint(type, allowed, typeResolver);

        if (isAllowed) continue; // Suppress warning

        // 3. Report
        var suggestion = '';
        if (allowed.isNotEmpty) {
          final allowedNames = allowed
              .map((a) => "'${describeConstraint(a, config.definitions)}'")
              .join(' or ');
          suggestion = ' Use $allowedNames instead.';
        }

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
            arguments: [type.getDisplayString(), paramName, suggestion],
          );
        } else if (node.name != null) {
          reporter.atToken(
            node.name!,
            _code,
            arguments: [type.getDisplayString(), paramName, suggestion],
          );
        } else {
          reporter.atNode(node, _code, arguments: [type.getDisplayString(), paramName, suggestion]);
        }
      }
    }
  }
}
