import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:architecture_lints/src/config/schema/inheritance_config.dart';
import 'package:architecture_lints/src/core/resolver/component_refiner.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// Mock Dependencies
class MockFileResolver extends Mock implements FileResolver {}

void main() {
  group('ComponentRefiner', () {
    late Directory tempDir;
    late MockFileResolver mockResolver;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('refiner_test_');
      mockResolver = MockFileResolver();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    /// Helper to create a ResolvedUnitResult from string content
    Future<ResolvedUnitResult> resolveContent(String content) async {
      final file = File(p.join(tempDir.path, 'lib/test.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);

      final result = await resolveFile(path: p.normalize(file.absolute.path));
      return result as ResolvedUnitResult;
    }

    /// Helper to create a candidate with a specific path match length
    Candidate createCandidate(ComponentConfig config, int matchLength) {
      return Candidate(config, matchLength);
    }

    test('should return null if no candidates are found', () async {
      final unit = await resolveContent('class A {}');
      when(() => mockResolver.resolveAllCandidates(any())).thenReturn([]);

      final refiner = ComponentRefiner(ArchitectureConfig.empty(), mockResolver);
      final result = refiner.refine(filePath: 'lib/test.dart', unit: unit);

      expect(result, isNull);
    });

    test('should prioritize Longer Path Match (Base Score)', () async {
      final cGeneral = const ComponentConfig(id: 'domain', paths: ['domain']);
      final cSpecific = const ComponentConfig(id: 'domain.usecase', paths: ['domain/usecases']);

      final candidates = [
        createCandidate(cGeneral, 6),
        createCandidate(cSpecific, 15),
      ];

      when(() => mockResolver.resolveAllCandidates(any())).thenReturn(candidates);
      when(() => mockResolver.resolveModule(any())).thenReturn(null);

      final unit = await resolveContent('class AnyClass {}');
      final refiner = ComponentRefiner(ArchitectureConfig.empty(), mockResolver);

      final result = refiner.refine(filePath: 'lib/test.dart', unit: unit);

      expect(result?.id, 'domain.usecase');
    });

    test('should prioritize Naming Pattern Match', () async {
      final cModel = const ComponentConfig(
        id: 'model',
        paths: ['data'],
        patterns: ['{{name}}Model'],
      );
      final cEntity = const ComponentConfig(
        id: 'entity',
        paths: ['data'],
        patterns: ['{{name}}Entity'],
      );

      final candidates = [
        createCandidate(cModel, 4),
        createCandidate(cEntity, 4),
      ];

      when(() => mockResolver.resolveAllCandidates(any())).thenReturn(candidates);
      when(() => mockResolver.resolveModule(any())).thenReturn(null);

      final unit = await resolveContent('class UserEntity {}');
      final refiner = ComponentRefiner(ArchitectureConfig.empty(), mockResolver);

      final result = refiner.refine(filePath: 'lib/test.dart', unit: unit);

      expect(result?.id, 'entity');
    });

    test('should prioritize Inheritance Match (Highest Weight)', () async {
      final cInterface = const ComponentConfig(
        id: 'repo.interface',
        paths: ['repo'],
      );
      final cImpl = const ComponentConfig(
        id: 'repo.impl',
        paths: ['repo'],
      );

      final config = ArchitectureConfig(
        components: [cInterface, cImpl],
        definitions: {
          'repo_base': const Definition(types: ['Repo']),
        },
        inheritances: [
          InheritanceConfig(
            onIds: ['repo.impl'],
            required: [const Definition(ref: 'repo_base')],
            allowed: [],
            forbidden: [],
          )
        ],
      );

      final candidates = [
        createCandidate(cInterface, 4),
        createCandidate(cImpl, 4),
      ];

      when(() => mockResolver.resolveAllCandidates(any())).thenReturn(candidates);
      when(() => mockResolver.resolveModule(any())).thenReturn(null);

      // FIX: Ensure MyRepoImpl is the first class so Refiner checks it
      final unit = await resolveContent('''
        class MyRepoImpl implements Repo {}
        class Repo {}
      ''');

      final refiner = ComponentRefiner(config, mockResolver);
      final result = refiner.refine(filePath: 'lib/test.dart', unit: unit);

      expect(result?.id, 'repo.impl');
    });

    test('should handle The "AuthSourceImpl" Scenario (Complex Tie-Break)', () async {
      final cInterface = const ComponentConfig(
        id: 'source.interface',
        paths: ['src'],
        patterns: ['{{name}}Source'],
      );
      final cImpl = const ComponentConfig(
        id: 'source.impl',
        paths: ['src'],
        patterns: ['{{name}}Impl'],
      );

      final config = ArchitectureConfig(
        components: [cInterface, cImpl],
        inheritances: [
          InheritanceConfig(
            onIds: ['source.impl'],
            required: [const Definition(component: 'source.interface')],
            allowed: [],
            forbidden: [],
          )
        ],
      );

      final candidates = [
        createCandidate(cInterface, 3),
        createCandidate(cImpl, 3),
      ];

      when(() => mockResolver.resolveAllCandidates(any())).thenReturn(candidates);
      when(() => mockResolver.resolveModule(any())).thenReturn(null);

      when(() => mockResolver.resolve(any())).thenAnswer((invocation) {
        return ComponentContext(
          filePath: 'mock/auth_source.dart',
          config: cInterface,
        );
      });

      // FIX: Ensure Implementation class is first
      final unit = await resolveContent('''
        class AuthSourceImpl implements AuthSource {}
        class AuthSource {}
      ''');

      final refiner = ComponentRefiner(config, mockResolver);
      final result = refiner.refine(filePath: 'lib/test.dart', unit: unit);

      expect(result?.id, 'source.impl');
    });
  });
}