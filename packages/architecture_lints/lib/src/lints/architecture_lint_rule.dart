import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/engines/configuration/config_loader.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/engines/component/component_refiner.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/engines/file/path_matcher.dart';
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

    if (context.sharedState.containsKey('arch_config_error')) {
      await super.startUp(resolver, context);
      return;
    }

    try {
      final config = await ConfigLoader.loadFromContext(resolver.path);

      if (config != null) {
        final fileResolver = FileResolver(config);
        context.sharedState[ArchitectureConfig] = config;
        context.sharedState[FileResolver] = fileResolver;

        try {
          final unit = await resolver.getResolvedUnitResult();
          final refiner = ComponentRefiner(config, fileResolver);
          final refinedComponent = refiner.refine(
            filePath: resolver.path,
            unit: unit,
          );
          if (refinedComponent != null) {
            context.sharedState[ComponentContext] = refinedComponent;
          }
        } catch (e, stack) {
          context.sharedState['arch_refiner_error'] = 'Refinement Error:\n$e\n$stack';
        }
      } else {
        // Config file not found via findRootPath
        context.sharedState['arch_config_status'] = 'NOT_FOUND';
      }
    } catch (e, stack) {
      // Capture the error thrown by ConfigLoader
      context.sharedState['arch_config_error'] = 'Configuration Error:\n$e\n$stack';
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

    // If config failed to load, we can't do anything (except debug rules might want to know)
    if (config == null || fileResolver == null) {
      // Allow debug rule to run even without config if it wants to report "No Config"
      if (this is! DebugComponentIdentityWrapper) return;
    }

    // Check Excludes
    if (config != null) {
      for (final exclude in config.excludes) {
        if (PathMatcher.matches(resolver.path, exclude)) return;
      }
    }

    // Retrieve Component (Refined -> Basic -> Null)
    var component = context.sharedState[ComponentContext] as ComponentContext?;

    // Fallback to basic resolution if Refiner didn't run or failed
    if (component == null && fileResolver != null) {
      try {
        component = fileResolver.resolve(resolver.path);
      } catch (e) {
        context.sharedState['arch_resolver_error'] = e.toString();
      }
    }

    runWithConfig(
      context: context,
      reporter: reporter,
      resolver: resolver,
      config: config ?? ArchitectureConfig.empty(),
      fileResolver: fileResolver ?? FileResolver(ArchitectureConfig.empty()),
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

// Marker interface used above to allow Debug rule to run even on failure
mixin DebugComponentIdentityWrapper {}
