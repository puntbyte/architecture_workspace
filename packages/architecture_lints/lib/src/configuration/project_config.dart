import 'component_config.dart';

class ProjectConfig {
  /// Map of 'id' -> ComponentConfig
  final Map<String, ComponentConfig> components;

  // We will add dependencies, type_safeties, etc., here later.
  // final List<DependencyRule> dependencies;

  const ProjectConfig({
    required this.components,
  });

  /// Finds which component a specific file belongs to.
  /// Returns null if the file is an "Orphan" (doesn't fit architecture).
  ComponentConfig? findComponentForFile(String relativePath) {
    // We iterate values.
    // TODO: Implement priority logic (longest path match)
    // For now, return the first match.
    for (final component in components.values) {
      if (component.matchesPath(relativePath)) {
        return component;
      }
    }
    return null;
  }
}