import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/config/detail/dependency_detail.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/dependency_config.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/lints/boundaries/rules/external_dependency_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:test/test.dart';

class TestExternalDependencyRule extends ExternalDependencyRule {
  final ArchitectureConfig mockConfig;

  const TestExternalDependencyRule(this.mockConfig);

  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    context.sharedState[ArchitectureConfig] = mockConfig;
    context.sharedState[FileResolver] = FileResolver(mockConfig);
    await super.startUp(resolver, context);
  }
}

void main() {
  group('ExternalDependencyRule', () {
    late Directory tempDir;
    late String projectPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ext_dep_test_');
      projectPath = p.canonicalize(tempDir.path);

      // Create pubspec.yaml
      File(p.join(projectPath, 'pubspec.yaml')).writeAsStringSync('name: test_project');

      final libUri = p.toUri(p.join(projectPath, 'lib'));
      final pkgConfigFile = File(p.join(projectPath, '.dart_tool', 'package_config.json'));
      pkgConfigFile.parent.createSync(recursive: true);

      // We simulate a package config that knows about 'flutter' and 'bloc'
      pkgConfigFile.writeAsStringSync('''
      {
        "configVersion": 2,
        "packages": [
          {"name": "test_project", "rootUri": "$libUri", "packageUri": "."},
          {"name": "flutter", "rootUri": "file:///flutter", "packageUri": "lib"},
          {"name": "bloc", "rootUri": "file:///bloc", "packageUri": "lib"},
          {"name": "equatable", "rootUri": "file:///equatable", "packageUri": "lib"}
        ]
      }
      ''');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<List<Diagnostic>> runLint({
      required String relativePath,
      required String content,
      required ArchitectureConfig config,
    }) async {
      // FIX: Use p.normalize to ensure separators are consistent (fixes Windows issues)
      final fullPath = p.normalize(p.join(projectPath, relativePath));

      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);

      final collection = AnalysisContextCollection(includedPaths: [projectPath]);
      final context = collection.contextFor(fullPath);
      final result = await context.currentSession.getResolvedUnit(fullPath);

      if (result is! ResolvedUnitResult) {
        throw StateError('Failed to resolve file: $fullPath');
      }

      final rule = TestExternalDependencyRule(config);
      return rule.testRun(result, pubspec: Pubspec('test_project'));
    }

    test('should report error when importing forbidden external package', () async {
      final config = ArchitectureConfig(
        components: [
          const ComponentConfig(id: 'domain', paths: ['domain']),
        ],
        dependencies: [
          DependencyConfig(
            onIds: const ['domain'],
            allowed: DependencyDetail.empty(),
            forbidden: const DependencyDetail(imports: ['package:flutter/**']),
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/user.dart',
        content: "import 'package:flutter/material.dart';\nclass User {}",
      );

      expect(errors, hasLength(1));
      expect(errors.first.message, contains('package:flutter/material.dart'));
    });

    test('should pass when importing allowed external package', () async {
      final config = ArchitectureConfig(
        components: [
          const ComponentConfig(id: 'domain', paths: ['domain']),
        ],
        dependencies: [
          DependencyConfig(
            onIds: const ['domain'],
            allowed: const DependencyDetail(imports: ['package:equatable/**']),
            forbidden: DependencyDetail.empty(),
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/user.dart',
        content: "import 'package:equatable/equatable.dart';\nclass User {}",
      );

      expect(errors, isEmpty);
    });

    test('should report error when importing package not in allowed list (Strict Mode)', () async {
      final config = ArchitectureConfig(
        components: [
          const ComponentConfig(id: 'domain', paths: ['domain']),
        ],
        dependencies: [
          DependencyConfig(
            onIds: const ['domain'],
            // Only allow bloc, implicitly forbidding flutter
            allowed: const DependencyDetail(imports: ['package:bloc/**']),
            forbidden: DependencyDetail.empty(),
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/user.dart',
        content: "import 'package:flutter/material.dart';\nclass User {}",
      );

      expect(errors, hasLength(1));
      expect(errors.first.message, contains('package:flutter/material.dart'));
    });

    test('should ignore internal project imports in external rule', () async {
      final config = ArchitectureConfig(
        components: [
          const ComponentConfig(id: 'domain', paths: ['domain']),
        ],
        dependencies: [
          DependencyConfig(
            onIds: const ['domain'],
            allowed: DependencyDetail.empty(),
            forbidden: const DependencyDetail(imports: ['package:flutter/**']),
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/user.dart',
        // 'test_project' matches our mock pubspec, so this counts as Internal.
        content: "import 'package:test_project/core/utils.dart';\nclass User {}",
      );

      expect(errors, isEmpty);
    });
  });
}
