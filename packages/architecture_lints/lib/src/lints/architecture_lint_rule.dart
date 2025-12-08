// lib/src/lints/inheritance_lint_rule.dart

import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/parsing/config_loader.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/component_refiner.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class ArchitectureLintRule extends DartLintRule {
  const ArchitectureLintRule({required super.code});

  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    if (context.sharedState.containsKey(ArchitectureConfig)) {
      await super.startUp(resolver, context);
      return;
    }

    final config = await ConfigLoader.loadFromContext(resolver.path);

    if (config != null) {
      final fileResolver = FileResolver(config);
      context.sharedState[ArchitectureConfig] = config;
      context.sharedState[FileResolver] = fileResolver;

      // REFINEMENT LOGIC
      final unit = await resolver.getResolvedUnitResult();

      // Use the new Refiner
      final refiner = ComponentRefiner(config, fileResolver);
      final refinedComponent = refiner.refine(filePath: resolver.path, unit: unit);

      // Store ComponentContext, not Config
      if (refinedComponent != null) context.sharedState[ComponentContext] = refinedComponent;
    }

    await super.startUp(resolver, context);
  }

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final config = context.sharedState[ArchitectureConfig] as ArchitectureConfig?;
    final fileResolver = context.sharedState[FileResolver] as FileResolver?;

    if (config == null || fileResolver == null) return;

    // 1. Try to get the Refined Component (from startUp)
    var component = context.sharedState[ComponentContext] as ComponentContext?;

    // 2. Fallback to basic Path Resolution if refiner failed or wasn't run
    component ??= fileResolver.resolve(resolver.path);

    runWithConfig(
      context: context,
      reporter: reporter,
      resolver: resolver,
      config: config,
      fileResolver: fileResolver,
      component: component,
    );
  }

  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  });
}
