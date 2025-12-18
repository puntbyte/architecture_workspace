import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/engines/configuration/config_loader.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart';

abstract class ArchitectureFixBase extends DartFix {
  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    try {
      if (!context.sharedState.containsKey(ArchitectureConfig)) {
        final config = await ConfigLoader.loadFromContext(resolver.path);
        if (config != null) context.sharedState[ArchitectureConfig] = config;
      }
      if (!context.sharedState.containsKey(ResolvedUnitResult)) {
        final unit = await resolver.getResolvedUnitResult();
        context.sharedState[ResolvedUnitResult] = unit;
      }
    } catch (e) {
      // Swallow startup errors
    }
    await super.startUp(resolver, context);
  }

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    try {
      final config = context.sharedState[ArchitectureConfig] as ArchitectureConfig?;
      final unitResult = context.sharedState[ResolvedUnitResult] as ResolvedUnitResult?;

      if (config == null || unitResult == null) return;

      runProtected(
        resolver: resolver,
        reporter: reporter,
        context: context,
        analysisError: analysisError,
        config: config,
        unitResult: unitResult,
      );
    } catch (e) {
      // print('[ArchitectureFix] Execution Failed: $e\n$stack');
    }
  }

  @protected
  void runProtected({
    required CustomLintResolver resolver,
    required ChangeReporter reporter,
    required CustomLintContext context,
    required Diagnostic analysisError,
    required ArchitectureConfig config,
    required ResolvedUnitResult unitResult,
  });
}
