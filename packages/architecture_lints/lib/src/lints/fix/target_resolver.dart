import 'package:architecture_lints/src/engines/file/file.dart';
import 'package:architecture_lints/src/engines/template/template.dart';
import 'package:architecture_lints/src/engines/variable/variable.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/action_definition.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:path/path.dart' as p;

class TargetResolver {
  final ArchitectureConfig config;
  final MustacheRenderer renderer;
  final FileResolver fileResolver;

  TargetResolver({
    required this.config,
    this.renderer = const MustacheRenderer(),
  }) : fileResolver = FileResolver(config);

  String? resolvePath({
    required ActionDefinition action,
    required VariableResolver variableResolver,
    required String currentPath,
  }) {
    // 1. Resolve Variables in Filename
    final templateContext = variableResolver.resolveMap(action.variables);
    final filenamePattern = action.write.filename!;

    // Interpolate ${...}
    final resolvedFilename = filenamePattern.replaceAllMapped(RegExp(r'\$\{(.*?)\}'), (match) {
      final expr = match.group(1);
      return expr != null ? variableResolver.resolve(expr).toString() : match.group(0)!;
    });

    // Render Mustache
    final fileName = renderer.render(resolvedFilename, templateContext);

    // 2. Calculate Directory
    final targetDir = _resolveSmartDirectory(
      currentPath: currentPath,
      targetComponentId: action.target.component,
    );

    if (targetDir == null) return null;
    return p.normalize(p.join(targetDir, fileName));
  }

  String? _resolveSmartDirectory({
    required String currentPath,
    required String? targetComponentId,
  }) {
    if (targetComponentId == null) return p.dirname(currentPath);

    final currentContext = fileResolver.resolve(currentPath);
    if (currentContext == null) return p.dirname(currentPath);

    ComponentDefinition? targetConfig;
    try {
      targetConfig = config.components.firstWhere(
            (c) => c.id == targetComponentId || c.id.endsWith('.$targetComponentId'),
      );
    } catch (_) {
      return p.dirname(currentPath);
    }

    final currentDir = p.dirname(currentPath);

    for (final path in currentContext.definition.paths) {
      final configPath = path.replaceAll('/', p.separator);
      if (currentDir.endsWith(configPath)) {
        final moduleRoot = currentDir.substring(0, currentDir.lastIndexOf(configPath));
        if (targetConfig.paths.isNotEmpty) {
          final targetRelative = targetConfig.paths.first.replaceAll('/', p.separator);
          return p.join(moduleRoot, targetRelative);
        }
      }
    }
    return currentDir;
  }
}