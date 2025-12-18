import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/engines/resolution/component_resolver.dart';
import 'package:architecture_lints/src/lints/consistency/logic/relationship_logic.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

class RelatedFileResolver with NamingLogic, RelationshipLogic {
  final ArchitectureConfig config;
  final ComponentResolver _componentResolver; // NEW

  RelatedFileResolver(this.config) : _componentResolver = ComponentResolver(config.components);

  Future<ResolvedUnitResult?> resolveRelated({
    required ComponentContext currentContext,
    required String targetComponentId,
    required AnalysisSession session,
  }) async {
    // 1. Find Target Config (Fuzzy)
    final targetConfig = _componentResolver.find(targetComponentId);

    if (targetConfig == null) return null;

    // 2. Extract Core Name
    final className = p.basenameWithoutExtension(currentContext.filePath).toPascalCase();
    final coreName = extractCoreName(className, currentContext);

    if (coreName == null) return null;

    // 3. Generate Target Info
    final targetClassName = generateTargetClassName(coreName, targetConfig);
    final targetFileName = '${toSnakeCase(targetClassName)}.dart';

    // 4. Calculate Path
    final targetPath = findTargetFilePath(
      currentFilePath: currentContext.filePath,
      currentComponent: currentContext.definition, // Pass definition
      targetComponent: targetConfig,
      targetFileName: targetFileName,
    );

    if (targetPath == null) return null;

    // 5. Resolve AST
    try {
      final result = await session.getResolvedUnit(targetPath);
      if (result is ResolvedUnitResult && result.exists) {
        return result;
      }
    } catch (_) {}

    return null;
  }

  @override
  String? findTargetFilePath({
    required String currentFilePath,
    required ComponentDefinition currentComponent, // Typed
    required ComponentDefinition targetComponent, // Typed
    required String targetFileName,
  }) {
    final currentDir = p.dirname(currentFilePath);

    // Paths are already full (e.g. "data/models")
    for (final path in currentComponent.paths) {
      final pathSegment = path.replaceAll('/', p.separator);

      if (currentDir.endsWith(pathSegment) || currentDir.endsWith(p.separator + pathSegment)) {
        final moduleRoot = currentDir.substring(0, currentDir.lastIndexOf(pathSegment));

        if (targetComponent.paths.isNotEmpty) {
          final targetRelative = targetComponent.paths.first.replaceAll('/', p.separator);
          final targetDir = p.join(moduleRoot, targetRelative);
          return p.normalize(p.join(targetDir, targetFileName));
        }
      }
    }
    return null;
  }

  /*
  /// Reconstructs the full directory path by walking up the ID hierarchy.
  /// id: 'data.model' -> path: 'data/models'
  String _calculateFullPath(ComponentDefinition component) {
    // Start with local path
    // ComponentDefinition.paths is a List. We take the first one as primary.
    if (component.paths.isEmpty) return '';
    var fullPath = component.paths.first;

    var currentId = component.id;

    // Walk up: data.model -> data
    while (currentId.contains('.')) {
      final lastDot = currentId.lastIndexOf('.');
      final parentId = currentId.substring(0, lastDot);

      final parent = config.components.firstWhereOrNull((c) => c.id == parentId);
      if (parent != null && parent.paths.isNotEmpty) {
        fullPath = p.join(parent.paths.first, fullPath);
      }

      currentId = parentId;
    }

    return fullPath;
  }*/
}

extension _StringExt on String {
  String toPascalCase() {
    if (isEmpty) return this;
    return split(
      '_',
    ).map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join();
  }
}
