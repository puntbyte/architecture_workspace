// test/src/utils/layer_resolver_test.dart
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:test/test.dart';

/// A helper function to create a complete and valid [CleanArchitectureConfig]
/// object specifically for testing the [LayerResolver].
/// It provides sensible defaults and allows overriding specific properties
/// to test various user configurations.
CleanArchitectureConfig makeTestConfig({
  String projectStructure = 'feature_first',
  String featuresRootPath = 'features',
  String domainPath = 'domain',
  List<String> domainEntitiesPaths = const ['entities'],
  List<String> domainRepositoriesPaths = const ['repositories'],
  List<String> domainUseCasesPaths = const ['usecases'],
  String dataPath = 'data',
  List<String> dataModelsPaths = const ['models'],
  List<String> dataDataSourcesPaths = const ['datasources'],
  List<String> dataRepositoriesPaths = const ['repositories'],
  String presentationPath = 'presentation',
  List<String> presentationManagerPaths = const ['managers'],
  List<String> presentationWidgetsPaths = const ['widgets'],
  List<String> presentationPagesPaths = const ['pages'],
}) {
  return CleanArchitectureConfig.fromMap({
    'project_structure': projectStructure,
    'feature_first_paths': {'features_root': featuresRootPath},
    'layer_first_paths': {'domain': domainPath, 'data': dataPath, 'presentation': presentationPath},
    'layer_definitions': {
      'domain': {
        'entities': domainEntitiesPaths,
        'repositories': domainRepositoriesPaths,
        'usecases': domainUseCasesPaths,
      },
      'data': {
        'models': dataModelsPaths,
        'data_sources': dataDataSourcesPaths,
        'repositories': dataRepositoriesPaths,
      },
      'presentation': {
        'managers': presentationManagerPaths,
        'widgets': presentationWidgetsPaths,
        'pages': presentationPagesPaths,
      },
    },
    'naming_conventions': {},
    'type_safety': {},
    'inheritance': {},
    'generation_options': {},
    'service_locator': {},
  });
}

void main() {
  group('LayerResolver', () {
    group('getLayer', () {
      group('with feature-first structure', () {
        final config = makeTestConfig();
        final resolver = LayerResolver(config);

        test('should return ArchLayer.domain for a domain file', () {
          const path = r'C:\project\lib\features\auth\domain\entities\user.dart';
          expect(resolver.getLayer(path), ArchLayer.domain);
        });

        test('should return ArchLayer.data for a data file', () {
          const path = r'C:\project\lib\features\auth\data\models\user_model.dart';
          expect(resolver.getLayer(path), ArchLayer.data);
        });

        test('should return ArchLayer.presentation for a presentation file', () {
          const path = r'C:\project\lib\features\auth\presentation\bloc\auth_bloc.dart';
          expect(resolver.getLayer(path), ArchLayer.presentation);
        });

        test('should return ArchLayer.unknown for a file outside a defined layer', () {
          const path = r'C:\project\lib\core\utils\types.dart';
          expect(resolver.getLayer(path), ArchLayer.unknown);
        });

        test('should handle Windows-style backslashes', () {
          const path = r'C:\project\lib\features\auth\domain\entities\user.dart';
          expect(resolver.getLayer(path), ArchLayer.domain);
        });
      });

      group('with layer-first structure', () {
        final config = makeTestConfig(projectStructure: 'layer_first');
        final resolver = LayerResolver(config);

        test('should return ArchLayer.domain for a domain file', () {
          const path = '/project/lib/domain/repositories/auth_repository.dart';
          expect(resolver.getLayer(path), ArchLayer.domain);
        });

        test('should return ArchLayer.data for a data file', () {
          const path = '/project/lib/data/datasources/auth_data_source.dart';
          expect(resolver.getLayer(path), ArchLayer.data);
        });
      });
    });

    group('getSubLayer', () {
      final config = makeTestConfig(
        domainEntitiesPaths: ['entities'],
        domainRepositoriesPaths: ['contracts'],
        domainUseCasesPaths: ['usecases', 'interactors'],
      );
      final resolver = LayerResolver(config);

      test('should return ArchSubLayer.entity for a domain entity file', () {
        const path = '/project/lib/features/auth/domain/entities/user_entity.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.entity);
      });

      test('should return ArchSubLayer.useCase for a domain use case file', () {
        const path = '/project/lib/features/auth/domain/usecases/get_user.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.useCase);
      });

      test('should return ArchSubLayer.domainRepository for a domain contract file', () {
        const path = '/project/lib/features/auth/domain/contracts/auth_repository.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.domainRepository);
      });

      test('should correctly identify a violations file in an entities directory', () {
        const path = r'C:\project\lib\features\auth\domain\entities\user.violations.dart';
        // The resolver should only care about the directory name 'entities', not the filename.
        expect(resolver.getSubLayer(path), ArchSubLayer.entity);
      });

      test('should correctly identify a violations file in a usecases directory', () {
        const path = r'C:\project\lib\features\auth\domain\usecases\get_user.violations.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.useCase);
      });

      test('should return unknown for a directory that does not match exactly', () {
        // This test ensures the old, buggy "fuzzy" matching is gone.
        // The directory is 'repository', but the config expects 'contracts'.
        const path = '/project/lib/features/auth/domain/repository/some_file.dart';
        expect(resolver.getSubLayer(path), ArchSubLayer.unknown);
      });
    });
  });
}
