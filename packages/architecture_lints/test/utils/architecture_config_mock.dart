// test/utils/architecture_config_mock.dart

/// A builder class to generate valid architecture.yaml content for testing.
///
/// Usage:
/// ```dart
/// final yaml = ArchitectureConfigMock()
///   .addComponent('domain.entity', path: 'domain/entities')
///   .toYaml();
/// ```
class ArchitectureConfigMock {
  final Map<String, _ComponentMock> _components = {};

  // Future: Add _dependencies, _layers, etc. here

  /// Adds a component definition to the config.
  ArchitectureConfigMock addComponent(
    String id, {
    String? name,
    String? path,
    String? pattern,
    String? antipattern,
    String? grammar,
  }) {
    _components[id] = _ComponentMock(
      name: name,
      path: path,
      pattern: pattern,
      antipattern: antipattern,
      grammar: grammar,
    );

    return this;
  }

  /// Generates the YAML string representation.
  String toYaml() {
    final buffer = StringBuffer();

    // 1. Components Section
    if (_components.isNotEmpty) {
      buffer.writeln('components:');
      _components.forEach((id, component) {
        buffer.write(component.toYamlString(id));
      });
    }

    // Future: Write dependencies, layers, etc. here

    return buffer.toString();
  }
}

/// Internal helper to represent a single component's properties
class _ComponentMock {
  final String? name;
  final String? path;
  final String? pattern;
  final String? antipattern;
  final String? grammar;

  _ComponentMock({
    this.name,
    this.path,
    this.pattern,
    this.antipattern,
    this.grammar,
  });

  String toYamlString(String id) {
    final buffer = StringBuffer()
      // 2 spaces indentation for the ID
      ..writeln('  $id:');

    // 4 spaces indentation for properties
    if (name != null) buffer.writeln("    name: '$name'");
    if (path != null) buffer.writeln("    path: '$path'");
    if (pattern != null) buffer.writeln("    pattern: '$pattern'");
    if (antipattern != null) buffer.writeln("    antipattern: '$antipattern'");
    if (grammar != null) buffer.writeln("    grammar: '$grammar'");

    return buffer.toString();
  }
}
