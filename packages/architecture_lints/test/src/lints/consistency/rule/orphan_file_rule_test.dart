import 'dart:io';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/consistency/rules/orphan_file_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class TestOrphanFileRule extends OrphanFileRule {
  final ArchitectureConfig mockConfig;
  const TestOrphanFileRule(this.mockConfig);

  @override
  Future<void> startUp(CustomLintResolver resolver, CustomLintContext context) async {
    context.sharedState[ArchitectureConfig] = mockConfig;
    context.sharedState[FileResolver] = FileResolver(mockConfig);
    await super.startUp(resolver, context);
  }
}

void main() {
  group('OrphanFileRule', () {
    late Directory tempDir;

    setUp(() => tempDir = Directory.systemTemp.createTempSync('orphan_test_'));
    tearDown(() => tempDir.deleteSync(recursive: true));

    Future<List<Diagnostic>> runLint(String relativePath, ArchitectureConfig config) async {
      final fullPath = p.joinAll([tempDir.path, ...relativePath.split('/')]);
      final file = File(fullPath)..createSync(recursive: true)..writeAsStringSync('class A {}');

      final normalizedPath = p.normalize(file.absolute.path);
      final result = await resolveFile(path: normalizedPath);

      return TestOrphanFileRule(config).testRun(result as ResolvedUnitResult);
    }

    test('should report orphan if file matches no component', () async {
      const config = ArchitectureConfig(components: [
        ComponentConfig(id: 'domain', paths: ['domain']),
      ]);

      // File is in 'presentation', so it is an orphan
      final errors = await runLint('lib/presentation/page.dart', config);
      expect(errors, hasLength(1));
      expect(errors.first.diagnosticCode.name, 'arch_orphan_file');
    });

    test('should NOT report if file matches a component', () async {
      const config = ArchitectureConfig(components: [
        ComponentConfig(id: 'domain', paths: ['domain']),
      ]);

      // File matches 'domain' path
      final errors = await runLint('lib/domain/usecase.dart', config);
      expect(errors, isEmpty);
    });
  });
}