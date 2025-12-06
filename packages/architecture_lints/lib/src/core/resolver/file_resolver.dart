import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/module_resolver.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/domain/module_context.dart';

class FileResolver {
  final ArchitectureConfig config;
  final ModuleResolver _moduleResolver;

  FileResolver(this.config) : _moduleResolver = ModuleResolver(config.modules);

  ComponentContext? resolve(String filePath) {
    final componentConfig = _resolveConfig(filePath);
    if (componentConfig == null) return null;

    final moduleContext = _moduleResolver.resolve(filePath);

    return ComponentContext(
      filePath: filePath,
      config: componentConfig,
      module: moduleContext,
    );
  }

  ComponentConfig? _resolveConfig(String filePath) {
    ComponentConfig? bestMatch;
    var bestMatchIndex = -1;
    var bestMatchLength = -1;

    final normalizedFile = filePath.replaceAll(r'\', '/');

    for (final component in config.components) {
      if (component.paths.isEmpty) continue;

      for (final path in component.paths) {
        final matchIndex = PathMatcher.getMatchIndex(normalizedFile, path);

        if (matchIndex != -1) {
          // 1. Prefer match deeper in the path (e.g. 'domain/entities' over 'domain')
          if (matchIndex > bestMatchIndex) {
            bestMatchIndex = matchIndex;
            bestMatchLength = path.length;
            bestMatch = component;
          }
          // 2. If start index is same (e.g. 'domain' vs 'domain')
          else if (matchIndex == bestMatchIndex) {
            // Prefer longer path match
            if (path.length > bestMatchLength) {
              bestMatchLength = path.length;
              bestMatch = component;
            }
            // 3. CRITICAL FIX: If paths are identical (Co-located), prefer the Child/Specific component.
            // We assume the Child has a longer ID (e.g. 'data.source.interface' > 'data.source')
            else if (path.length == bestMatchLength) {
              if (component.id.length > (bestMatch?.id.length ?? 0)) {
                bestMatch = component;
              }
            }
          }
        }
      }
    }

    return bestMatch;
  }

  ModuleContext? resolveModule(String filePath) {
    return _moduleResolver.resolve(filePath);
  }
}
