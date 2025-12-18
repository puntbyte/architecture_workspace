import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/engines/resolution/type_resolver.dart';
import 'package:architecture_lints/src/lints/safety/base/type_safety_base_rule.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/policies/type_safety_policy.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class TypeSafetyReturnForbiddenRule extends TypeSafetyBaseRule {
  static const _code = LintCode(
    name: 'arch_safety_return_forbidden',
    problemMessage: 'Invalid Return Type: "{0}" is forbidden.{1}',
    correctionMessage: 'Change the return type to a permitted type.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const TypeSafetyReturnForbiddenRule() : super(code: _code);

  @override
  void checkReturn({
    required MethodDeclaration node,
    required DartType type,
    required List<TypeSafetyPolicy> rules,
    required ArchitectureConfig config,
    required TypeResolver typeResolver,
    required DiagnosticReporter reporter,
  }) {
    if (node.returnType == null) return;

    for (final rule in rules) {
      final forbidden = rule.forbidden.where((c) => c.kind == 'return').toList();
      final allowed = rule.allowed.where((c) => c.kind == 'return').toList();

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

        final returnNode = node.returnType!;

        if (returnNode is NamedType) {
          reporter.atToken(
            returnNode.name,
            _code,
            arguments: [type.getDisplayString(), suggestion],
          );
        } else {
          reporter.atNode(
            returnNode,
            _code,
            arguments: [type.getDisplayString(), suggestion],
          );
        }
      }
    }
  }
}