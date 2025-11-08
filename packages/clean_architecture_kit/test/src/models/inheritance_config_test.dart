// test/src/models/inheritance_config_test.dart

import 'package:clean_architecture_kit/src/models/inheritance_config.dart';
import 'package:test/test.dart';

void main() {
  group('InheritanceConfig', () {
    group('fromMap factory', () {
      test('should parse a complete map with all custom values', () {
        final map = {
          'entity_base_name': 'MyBaseEntity',
          'entity_base_path': 'package:my_core/my_entity.dart',
          'repository_base_name': 'MyBaseRepo',
          'repository_base_path': 'package:my_core/my_repo.dart',
          'unary_use_case_name': 'MyUnary',
          'unary_use_case_path': 'package:my_core/my_usecase.dart',
          'nullary_use_case_name': 'MyNullary',
          'nullary_use_case_path': 'package:my_core/my_usecase.dart',
        };

        final config = InheritanceConfig.fromMap(map);

        expect(config.entityBaseName, 'MyBaseEntity');
        expect(config.entityBasePath, 'package:my_core/my_entity.dart');
        expect(config.repositoryBaseName, 'MyBaseRepo');
        expect(config.repositoryBasePath, 'package:my_core/my_repo.dart');
        expect(config.unaryUseCaseName, 'MyUnary');
        expect(config.unaryUseCasePath, 'package:my_core/my_usecase.dart');
        expect(config.nullaryUseCaseName, 'MyNullary');
        expect(config.nullaryUseCasePath, 'package:my_core/my_usecase.dart');
      });

      test('should use default values when map is empty', () {
        final map = <String, dynamic>{};
        final config = InheritanceConfig.fromMap(map);

        // Assumes _CoreDefaults are used.
        expect(config.entityBaseName, 'Entity');
        expect(config.repositoryBaseName, 'Repository');
        expect(config.unaryUseCaseName, 'UnaryUseCase');
        expect(config.nullaryUseCaseName, 'NullaryUseCase');
        expect(config.entityBasePath, 'package:clean_architecture_core/clean_architecture_core.dart');
      });

      test('should use a mix of provided and default values', () {
        final map = {
          'entity_base_name': 'CustomEntity',
          'unary_use_case_path': 'package:my_custom/usecase.dart',
        };

        final config = InheritanceConfig.fromMap(map);

        expect(config.entityBaseName, 'CustomEntity'); // Custom value
        expect(config.repositoryBaseName, 'Repository'); // Default value
        expect(config.unaryUseCasePath, 'package:my_custom/usecase.dart'); // Custom value
        expect(config.nullaryUseCasePath, 'package:clean_architecture_core/clean_architecture_core.dart'); // Default value
      });
    });
  });
}
