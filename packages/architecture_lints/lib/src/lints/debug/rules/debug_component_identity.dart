import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/lints/debug/logic/debug_rule_runner.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DebugComponentIdentity extends ArchitectureRule with DebugComponentIdentityWrapper {
  static const _code = LintCode(
    name: 'debug_component_identity',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  const DebugComponentIdentity() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    // 1. Retrieve errors captured during startUp()
    final configError = context.sharedState['arch_config_error']?.toString();
    final refinerError = context.sharedState['arch_refiner_error']?.toString();
    final resolverError = context.sharedState['arch_resolver_error']?.toString();

    final combinedError = configError ?? refinerError ?? resolverError;

    // 2. Delegate to Runner
    DebugRuleRunner(
      context: context,
      reporter: reporter,
      resolver: resolver,
      config: config,
      fileResolver: fileResolver,
      component: component,
      code: _code,
      globalError: combinedError,
    ).register();
  }
}
