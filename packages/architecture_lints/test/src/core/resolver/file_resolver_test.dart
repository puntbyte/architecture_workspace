import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('FileResolver', () {
    late ArchitectureConfig mockConfig;
    late FileResolver resolver;

    setUp(() {
      mockConfig = const ArchitectureConfig(
        modules: [
          ModuleConfig(key: 'feature', path: 'features/{{name}}'),
          ModuleConfig(key: 'core', path: 'core'),
        ],
        components: [
          // 1. Simple Path
          ComponentConfig(
            id: 'domain.usecase',
            paths: ['domain/usecases'],
            patterns: ['{{name}}UseCase'],
          ),

          // 2. Nested Layers (General vs Specific)
          ComponentConfig(
            id: 'data',
            paths: ['data'], // Short path (length ~4)
          ),
          ComponentConfig(
            id: 'data.repository',
            paths: ['data/repositories'], // Long path (length ~17)
          ),

          // 3. Co-located Components (Same Path)
          // Used to test ID length tie-breaking
          ComponentConfig(
            id: 'source.interface', // Length 16
            paths: ['data/sources'],
          ),
          ComponentConfig(
            id: 'source.implementation', // Length 21 (Longer)
            paths: ['data/sources'],
          ),

          // 4. Wildcards
          ComponentConfig(
            id: 'presentation.page',
            paths: ['features/{{name}}/presentation/pages'],
          ),
        ],
      );

      resolver = FileResolver(mockConfig);
    });

    test('should resolve component by exact path match', () {
      final result = resolver.resolve('lib/domain/usecases/login_usecase.dart');

      expect(result, isNotNull);
      expect(result!.id, 'domain.usecase');
    });

    test('should resolve component containing {{name}} wildcard', () {
      final result = resolver.resolve(
        'lib/features/auth/presentation/pages/login_page.dart',
      );

      expect(result, isNotNull);
      expect(result!.id, 'presentation.page');
    });

    test('should extract ModuleContext correctly', () {
      final result = resolver.resolve(
        'lib/features/auth/presentation/pages/login_page.dart',
      );

      expect(result?.module, isNotNull);
      expect(result?.module?.key, 'feature');
      expect(result?.module?.name, 'auth');
    });

    group('Specificity Logic (Longest Path Wins)', () {
      test('should prefer specific path over general parent path', () {
        // File matches both 'data' and 'data/repositories'.
        // 'data/repositories' is longer, so it should win.
        final result = resolver.resolve('lib/data/repositories/auth_repository.dart');

        expect(result?.id, 'data.repository');
      });

      test('should fall back to general path if specific does not match', () {
        // File is in 'data/models'. Matches 'data', but NOT 'data/repositories'.
        final result = resolver.resolve('lib/data/models/user_model.dart');

        expect(result?.id, 'data');
      });
    });

    group('Tie-Breaker Logic (Same Path)', () {
      test('should prefer Longest ID when paths are identical', () {
        // Both 'source.interface' and 'source.implementation' match 'data/sources'.
        // The resolver (without AST refinement) uses ID length as a heuristic for specificity.
        // 'source.implementation' (21 chars) > 'source.interface' (16 chars).

        final result = resolver.resolve('lib/data/sources/any_file.dart');

        expect(result?.id, 'source.implementation');
      });
    });

    group('resolveAllCandidates', () {
      test('should return ALL matches for Refiner to use', () {
        // 'data/sources' matches:
        // 1. data (Path: data)
        // 2. source.interface (Path: data/sources)
        // 3. source.implementation (Path: data/sources)

        final candidates = resolver.resolveAllCandidates('lib/data/sources/file.dart');

        expect(candidates.length, 3);

        final ids = candidates.map((c) => c.component.id).toList();
        expect(ids, containsAll(['data', 'source.interface', 'source.implementation']));
      });
    });

    test('should return null for unrelated files', () {
      final result = resolver.resolve('lib/main.dart');
      expect(result, isNull);
    });

    test('should handle Windows file separators', () {
      final result = resolver.resolve(r'lib\domain\usecases\login_usecase.dart');
      expect(result?.id, 'domain.usecase');
    });
  });
}