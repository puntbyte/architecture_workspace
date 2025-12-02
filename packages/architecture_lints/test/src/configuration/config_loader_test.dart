// test/src/configuration/config_loader_test.dart

import 'package:architecture_lints/src/configuration/config_loader.dart';
import 'package:architecture_lints/src/configuration/project_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

// Import the new helper
import '../../utils/architecture_config_mock.dart';

void main() {
  group('ConfigLoader', () {
    test('should return an empty config if the yaml contains no components', () async {
      // Empty mock produces empty YAML string (or just unrelated keys)
      final yamlContent = ArchitectureConfigMock().toYaml();

      final config = await ConfigLoaderExtension.parseString(yamlContent);

      expect(config.components, isEmpty);
    });

    test('should parse a single component with all fields defined', () async {
      final yamlContent = ArchitectureConfigMock()
          .addComponent(
            'domain.entity',
            name: 'Entity',
            path: 'domain/entities',
            pattern: '{{name}}',
            grammar: '{{noun}}',
          )
          .toYaml();

      final config = await ConfigLoaderExtension.parseString(yamlContent);

      expect(config.components.length, 1);

      final component = config.components['domain.entity'];
      expect(component, isNotNull);
      expect(component?.name, 'Entity');
      expect(component?.pattern, '{{name}}');
      expect(component?.grammar, '{{noun}}');
    });

    test('should normalize file paths based on the operating system', () async {
      final yamlContent = ArchitectureConfigMock()
          .addComponent(
            'data.repository',
            path: 'data/repositories/impl', // Unix style input
          )
          .toYaml();

      final config = await ConfigLoaderExtension.parseString(yamlContent);

      final component = config.components['data.repository'];

      // Expect OS-specific result
      expect(component?.path, p.normalize('data/repositories/impl'));
    });

    test('should use the component ID as the default name if "name" is missing', () async {
      final yamlContent = ArchitectureConfigMock()
          .addComponent(
            'domain.value_object',
            path: 'domain/values',
            // name is intentionally omitted
          )
          .toYaml();

      final config = await ConfigLoaderExtension.parseString(yamlContent);

      final component = config.components['domain.value_object'];
      expect(component?.name, 'domain.value_object');
    });

    test('should return null properties for undefined optional fields', () async {
      final yamlContent = ArchitectureConfigMock()
          .addComponent(
            'minimal',
            path: 'lib',
          )
          .toYaml();

      final config = await ConfigLoaderExtension.parseString(yamlContent);

      final component = config.components['minimal'];
      expect(component?.pattern, isNull);
      expect(component?.antipattern, isNull);
      expect(component?.grammar, isNull);
    });
  });
}

extension ConfigLoaderExtension on ConfigLoader {
  static Future<ProjectConfig> parseString(String content) async {
    // If string is empty, loadYaml returns null or empty string, handle gracefully
    if (content.trim().isEmpty) {
      return ConfigLoader.parseYaml(YamlMap());
    }

    final yaml = loadYaml(content);
    if (yaml is YamlMap) {
      return ConfigLoader.parseYaml(yaml);
    }

    // Fallback for empty/invalid yaml in tests
    return ConfigLoader.parseYaml(YamlMap());
  }
}
