// test/src/analysis/layer_resolver_test.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('LayerResolver', () {
    group('getComponent (from path)', () {
      group('when in a feature-first project', () {
        final config = makeConfig(projectStructure: 'feature_first');
        final resolver = LayerResolver(config);

        test('should resolve component from domain layer', () {
          const path = '/project/lib/features/auth/domain/contracts/auth_repository.dart';
          expect(resolver.getComponent(path), ArchComponent.contract);
        });

        test('should resolve component from data layer', () {
          const path = '/project/lib/features/auth/data/models/user_model.dart';
          expect(resolver.getComponent(path), ArchComponent.model);
        });

        test('should resolve component from presentation layer', () {
          const path = '/project/lib/features/auth/presentation/widgets/button.dart';
          expect(resolver.getComponent(path), ArchComponent.widget);
        });

        test('should return unknown for files not in a defined architectural path', () {
          const path = '/project/lib/core/utils/types.dart';
          expect(resolver.getComponent(path), ArchComponent.unknown);
        });
      });

      group('when in a layer-first project', () {
        final config = makeConfig(projectStructure: 'layer_first');
        final resolver = LayerResolver(config);

        test('should resolve component from domain layer', () {
          const path = '/project/lib/domain/entities/user.dart';
          expect(resolver.getComponent(path), ArchComponent.entity);
        });

        test('should resolve component using a custom directory name', () {
          final customConfig = makeConfig(
            projectStructure: 'layer_first',
            sourceDir: 'data_sources',
          );
          final customResolver = LayerResolver(customConfig);
          const path = '/project/lib/data/data_sources/remote_source.dart';
          expect(customResolver.getComponent(path), ArchComponent.source);
        });
      });
    });

    group('getComponent (with refinement from class name)', () {
      final config = makeConfig();
      final resolver = LayerResolver(config);
      const managerPath = '/project/lib/features/auth/presentation/managers/auth_bloc.dart';
      const sourcePath = '/project/lib/features/auth/data/sources/auth_source.dart';

      test('should refine a manager path to an Event', () {
        final component = resolver.getComponent(managerPath, className: 'AuthEvent');
        expect(component, ArchComponent.event);
      });

      test('should refine a manager path to a State implementation', () {
        final component = resolver.getComponent(managerPath, className: 'AuthLoading');
        expect(component, ArchComponent.stateImplementation);
      });

      test('should default to a Manager if no specific component name matches', () {
        final component = resolver.getComponent(managerPath, className: 'AuthBloc');
        expect(component, ArchComponent.manager);
      });

      test('should refine a source path to an Implementation', () {
        final component = resolver.getComponent(sourcePath, className: 'DefaultAuthDataSource');
        expect(component, ArchComponent.sourceImplementation);
      });

      test('should default to a Source interface if implementation name does not match', () {
        final component = resolver.getComponent(sourcePath, className: 'AuthDataSource');
        expect(component, ArchComponent.source);
      });
    });
  });
}
