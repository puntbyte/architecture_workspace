import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('FileResolver', () {
    late ArchitectureConfig mockConfig;
    late FileResolver resolver;

    setUp(() {
      mockConfig = const ArchitectureConfig(
        components: [
          ComponentConfig(
            id: 'domain.usecase',
            paths: ['domain/usecases'],
            patterns: ['{{name}}UseCase'],
          ),
          ComponentConfig(
            id: 'domain.entity',
            paths: ['domain/entities'],
            patterns: ['{{name}}'],
          ),
          // Component with multiple valid paths
          ComponentConfig(
            id: 'presentation.manager',
            paths: ['presentation/managers', 'presentation/blocs', 'presentation/cubits'],
            patterns: ['{{name}}Cubit', '{{name}}Bloc'],
          ),
          ComponentConfig(
            id: 'feature.layer',
            paths: ['features/{{name}}/data'],
            patterns: ['.*'],
          ),
          // A catch-all or overlapping path
          ComponentConfig(
            id: 'general.domain',
            paths: ['domain'],
            patterns: ['.*'],
          ),
        ],
      );
      resolver = FileResolver(mockConfig);
    });

    test('should resolve specific component when path matches exactly', () {
      const filePath = 'lib/domain/usecases/login_usecase.dart';
      final result = resolver.resolve(filePath);

      expect(result, isNotNull);
      expect(result?.id, 'domain.usecase');
    });

    test('should resolve component defined with multiple paths (Match 1)', () {
      // Defined in paths: ['presentation/managers', ...]
      const filePath = 'lib/presentation/managers/auth_manager.dart';
      final result = resolver.resolve(filePath);

      expect(result?.id, 'presentation.manager');
    });

    test('should resolve component defined with multiple paths (Match 2)', () {
      // Defined in paths: [..., 'presentation/blocs', ...]
      const filePath = 'lib/presentation/blocs/login_bloc.dart';
      final result = resolver.resolve(filePath);

      expect(result?.id, 'presentation.manager');
    });

    test('should resolve component with {{name}} wildcard', () {
      const filePath = 'lib/features/auth/data/repo_impl.dart';
      final result = resolver.resolve(filePath);

      expect(result, isNotNull);
      expect(result?.id, 'feature.layer');
    });

    test('should return first matching component (Priority Rule)', () {
      // Both 'domain.usecase' (path: domain/usecases)
      // and 'general.domain' (path: domain) match this file.
      // Since 'domain.usecase' is defined FIRST in the list, it should win.
      const filePath = 'lib/domain/usecases/login_usecase.dart';
      final result = resolver.resolve(filePath);

      expect(result?.id, 'domain.usecase');
    });

    test('should return null when no component matches', () {
      const filePath = 'lib/core/widgets/button.dart';
      final result = resolver.resolve(filePath);

      expect(result, isNull);
    });

    test('should ignore components with empty paths list', () {
      const configWithEmptyPaths = ArchitectureConfig(
        components: [
          ComponentConfig(id: 'abstract.base', paths: []), // Should be skipped
          ComponentConfig(id: 'concrete', paths: ['lib/concrete']),
        ],
      );
      const localResolver = FileResolver(configWithEmptyPaths);

      // Even if file path contains nothing relevant, it shouldn't crash or match empty
      const filePath = 'lib/concrete/impl.dart';
      final result = localResolver.resolve(filePath);

      expect(result?.id, 'concrete');
    });
  });
}
