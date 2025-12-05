import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:architecture_lints/src/domain/module_context.dart';

mixin ModuleLogic {
  ModuleContext? resolveModuleContext(String filePath, List<ModuleConfig> modules) {
    final normalizedFile = filePath.replaceAll(r'\', '/');

    for (final module in modules) {
      if (!module.path.contains('{{name}}')) continue;

      final pattern = PathMatcher.escapeRegex(module.path)
          .replaceAll(r'\{\{name\}\}', '([^/]+)');

      final regex = RegExp('/$pattern/');
      final match = regex.firstMatch(normalizedFile);

      if (match != null && match.groupCount >= 1) {
        return ModuleContext(
          config: module,
          name: match.group(1)!,
        );
      }
    }
    return null;
  }
}
