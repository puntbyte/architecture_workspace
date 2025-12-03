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
          // 1. Broad / High-level Layer
          ComponentConfig(
            id: 'domain_layer',
            paths: ['domain'], // Short path
          ),
          // 2. Specific Component INSIDE the broad layer (The Nested Scenario)
          ComponentConfig(
            id: 'domain_usecase',
            paths: ['domain/usecases'], // Longer, more specific path
          ),
          // 3. Even MORE specific (Deep nesting)
          ComponentConfig(
            id: 'domain_usecase_v2',
            paths: ['domain/usecases/v2'],
          ),
          // 4. Component with multiple disparate paths
          ComponentConfig(
            id: 'state_manager',
            paths: ['presentation/blocs', 'presentation/cubits'],
          ),
          // 5. Wildcard Component
          ComponentConfig(
            id: 'feature_data',
            paths: ['features/{{name}}/data'],
          ),
        ],
      );
      resolver = FileResolver(mockConfig);
    });

    group('Specificity Rules (The "Parent vs Child" Fix)', () {
      test('should resolve to the MOST SPECIFIC component when paths overlap', () {
        // This file matches 'domain' (len 6) AND 'domain/usecases' (len 15).
        // It should pick 'domain/usecases' because it is longer/more specific.
        const filePath = 'lib/domain/usecases/login_usecase.dart';
        final result = resolver.resolve(filePath);

        expect(result, isNotNull);
        expect(result?.id, 'domain_usecase'); // NOT 'domain_layer'
      });

      test('should resolve to the Deepest component available', () {
        // Matches 'domain', 'domain/usecases', AND 'domain/usecases/v2'
        const filePath = 'lib/domain/usecases/v2/new_login.dart';
        final result = resolver.resolve(filePath);

        expect(result?.id, 'domain_usecase_v2');
      });

      test('should resolve to the broad layer if file is not in specific sub-folder', () {
        // Matches 'domain', but NOT 'domain/usecases'
        const filePath = 'lib/domain/exceptions/failure.dart';
        final result = resolver.resolve(filePath);

        expect(result?.id, 'domain_layer');
      });
    });

    group('Multiple Paths Logic', () {
      test('should resolve component via First path', () {
        const filePath = 'lib/presentation/blocs/auth_bloc.dart';
        final result = resolver.resolve(filePath);
        expect(result?.id, 'state_manager');
      });

      test('should resolve component via Second path', () {
        const filePath = 'lib/presentation/cubits/cart_cubit.dart';
        final result = resolver.resolve(filePath);
        expect(result?.id, 'state_manager');
      });
    });

    group('Wildcard Logic', () {
      test('should resolve wildcard paths correctly', () {
        // 'features/{{name}}/data' (len ~19) vs 'features' (if it existed)
        const filePath = 'lib/features/auth/data/repository.dart';
        final result = resolver.resolve(filePath);
        expect(result?.id, 'feature_data');
      });

      test('should handle wildcard vs specific overlap preference', () {
        // If we had a generic 'features/{{name}}' and a specific 'features/{{name}}/data',
        // 'data' is longer, so it should win.
        const localConfig = ArchitectureConfig(components: [
          ComponentConfig(id: 'feature_root', paths: ['features/{{name}}']),
          ComponentConfig(id: 'feature_data', paths: ['features/{{name}}/data']),
        ]);
        const localResolver = FileResolver(localConfig);

        const filePath = 'lib/features/auth/data/repo.dart';
        expect(localResolver.resolve(filePath)?.id, 'feature_data');
      });
    });

    group('Edge Cases', () {
      test('should return null if no path matches', () {
        const filePath = 'lib/random/orphan.dart';
        expect(resolver.resolve(filePath), isNull);
      });

      test('should handle empty paths safely', () {
        const localConfig = ArchitectureConfig(components: [
          ComponentConfig(id: 'bad_config', paths: []),
        ]);
        final localResolver = FileResolver(localConfig);

        expect(localResolver.resolve('lib/any.dart'), isNull);
      });

      test('should match partial folder names strictly if PathMatcher enforces it', () {
        // Ensure 'domain' doesn't match 'domain_stuff'
        // This relies on PathMatcher implementation, but FileResolver calls it.
        const filePath = 'lib/domain_stuff/file.dart';

        // Assuming PathMatcher checks for directory boundaries or containment:
        // If config is 'domain', and file is 'domain_stuff', simplistic 'contains' might match.
        // BUT, our previous tests showed PathMatcher handles separators.
        // If 'domain' matches 'domain_stuff', specificity logic implies:
        // 'domain' (len 6) vs nothing else.
        // Ideally, this should NOT match.
        // NOTE: This test depends on your PathMatcher.matches implementation.
        // If PathMatcher uses simple `.contains()`, this might fail (it would match).
        // If PathMatcher uses separator checks, it passes (returns null).

        // Based on our PathMatcher using simple `contains` in the last iteration:
        // If you want strict folder matching, PathMatcher needs update.
        // For now, let's verify exact behavior.

        final result = resolver.resolve(filePath);
        // If result is 'domain_layer', it means our PathMatcher is loose (contains 'domain').
        // If result is null, it means PathMatcher is strict.
        // Let's expect null for a robust system, but adjust if you kept simple contains.
        expect(result, isNull);
      });
    });
  });
}