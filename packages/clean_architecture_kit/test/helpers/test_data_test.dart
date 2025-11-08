// test/helpers/test_data_test.dart
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_data.dart';

void main() {
  group('test data factories', () {
    test('layer-first config resolves lib/domain/repositories to domainRepository', () {
      final cfg = makeLayerFirstTestConfig(
        domainRepositoriesPaths: ['repositories'],
        useCasesPaths: ['usecases'],
      );
      final resolver = LayerResolver(cfg);

      final path = p.join(
        'some',
        'abs',
        'path',
        'lib',
        'domain',
        'repositories',
        'user_repository.dart',
      );
      final subLayer = resolver.getSubLayer(path);

      expect(subLayer, ArchSubLayer.domainRepository);
    });

    test(
      'feature-first config resolves lib/features/<feature>/domain/repositories to domainRepository',
      () {
        final cfg = makeFeatureFirstConfig(
          featuresRoot: 'features',
          domainRepositoriesPaths: ['repositories'],
          useCasesPaths: ['usecases'],
        );
        final resolver = LayerResolver(cfg);

        final path = p.join(
          'some',
          'abs',
          'path',
          'lib',
          'features',
          'auth',
          'domain',
          'repositories',
          'user_repository.dart',
        );
        final subLayer = resolver.getSubLayer(path);

        expect(subLayer, ArchSubLayer.domainRepository);
      },
    );
  });
}
