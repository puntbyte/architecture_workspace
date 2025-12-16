// lib/src/core/resolver/module_resolver.dart
import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:architecture_lints/src/domain/module_context.dart';
import 'package:architecture_lints/src/engines/file/path_matcher.dart';

class ModuleResolver {
  final List<ModuleConfig> modules;

  const ModuleResolver(this.modules);

  ModuleContext? resolve(String filePath) {
    final normalizedFile = filePath.replaceAll(r'\', '/');

    // We prioritize matches inside the 'lib/' directory to avoid matching
    // project root folders that happen to have the same name.
    final libIndex = normalizedFile.indexOf('/lib/');
    final searchStart = libIndex == -1 ? 0 : libIndex;

    final placeholder = ConfigKeys.placeholder.name; // r'${name}'

    for (final module in modules) {
      // 1. Dynamic Modules (e.g. features/${name})
      if (module.path.contains(placeholder)) {
        // Build Regex: features/${name} -> features/([^/]+)
        final pattern = PathMatcher.escapeRegex(module.path)
            .replaceAll(PathMatcher.escapeRegex(placeholder), '([^/]+)');

        // We look for the pattern surrounded by slashes OR at the start of a relative path
        // e.g. /features/auth/
        final regex = RegExp('/$pattern/');
        final match = regex.firstMatch(normalizedFile.substring(searchStart));

        if (match != null && match.groupCount >= 1) {
          return ModuleContext(
            config: module,
            name: match.group(1)!,
          );
        }
      }
      // 2. Static Modules (e.g. core)
      else {
        // Strict directory match
        if (normalizedFile.indexOf('/${module.path}/', searchStart) != -1) {
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
