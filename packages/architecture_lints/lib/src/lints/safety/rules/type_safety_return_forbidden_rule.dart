import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/type_safety_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/safety/base/type_safety_base_rule.dart';
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
    required List<TypeSafetyConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
  }) {
    for (final rule in rules) {
      final forbidden = rule.forbidden.where((c) => c.kind == 'return').toList();
      final allowed = rule.allowed.where((c) => c.kind == 'return').toList();

      // Skip if no forbidden rules exist
      if (forbidden.isEmpty) continue;

      // 1. Check if the type matches any FORBIDDEN rule
      final isForbidden = matchesAnyConstraint(
          type,
          forbidden,
          fileResolver,
          config.typeDefinitions
      );

      if (isForbidden) {
        // 2. CRITICAL FIX: "Specific Beats General"
        // If the type is ALSO matched by an ALLOWED rule, assume the user
        // intended to allow this specific case (e.g., allow FutureEither vs forbid Future).
        final isAllowed = matchesAnyConstraint(
            type,
            allowed,
            fileResolver,
            config.typeDefinitions
        );

        if (isAllowed) continue; // Skip reporting

        // 3. Generate Suggestion
        var suggestion = '';
        if (allowed.isNotEmpty) {
          final allowedNames = allowed
              .map((a) => "'${describeConstraint(a, config.typeDefinitions)}'")
              .join(' or ');
          suggestion = ' Use $allowedNames instead.';
        }

        reporter.atNode(
          node.returnType!,
          _code,
          arguments: [
            type.getDisplayString(),
            suggestion,
          ],
        );
      }
    }
  }
}