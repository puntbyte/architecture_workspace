// lib/src/lints/boundaries/logic/module_logic.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:architecture_lints/src/domain/module_context.dart';

mixin ModuleLogic {
  ModuleContext? resolveModuleContext(String filePath, List<ModuleConfig> modules) {
    final normalizedFile = filePath.replaceAll(r'\', '/');
    final placeholder = ConfigKeys.placeholder.name; // r'${name}'

    for (final module in modules) {
      // 1. Dynamic Modules (e.g. features/${name})
      if (module.path.contains(placeholder)) {
        // Step A: Escape the config path (turns 'features/${name}' into 'features/\$\{name\}')
        final escapedPath = PathMatcher.escapeRegex(module.path);

        // Step B: Escape the placeholder itself to match the escaped path
        // (turns '${name}' into '\$\{name\}')
        final escapedPlaceholder = PathMatcher.escapeRegex(placeholder);

        // Step C: Replace the placeholder with a capture group
        // Pattern becomes: features/([^/]+)
        final pattern = escapedPath.replaceAll(escapedPlaceholder, '([^/]+)');

        // Step D: Match against file path
        // We look for the pattern surrounded by slashes to ensure directory matching
        final regex = RegExp('/$pattern/');
        final match = regex.firstMatch(normalizedFile);

        if (match != null && match.groupCount >= 1) {
          return ModuleContext(
            config: module,
            name: match.group(1)!,
          );
        }
      }
      // 2. Static Modules (e.g. core)
      else {
        if (normalizedFile.contains('/${module.path}/')) {
          return ModuleContext(
            config: module,
            name: module.key,
          );
        }
      }
    }
    return null;
  }
}
