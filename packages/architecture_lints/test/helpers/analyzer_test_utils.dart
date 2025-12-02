// test/helpers/analyzer_test_utils.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/models/configs/architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

import 'test_data.dart';

class AnalyzerTestUtils {
  final String projectRoot;
  final PhysicalResourceProvider resourceProvider;
  late final AnalysisContextCollection contextCollection;
  late final LayerResolver layerResolver;
  final Set<String> _createdFiles = {};

  AnalyzerTestUtils(this.projectRoot)
      : resourceProvider = PhysicalResourceProvider.INSTANCE {
    contextCollection = AnalysisContextCollection(
      includedPaths: [projectRoot],
      resourceProvider: resourceProvider,
    );
    layerResolver = LayerResolver(makeConfig());
  }

  void writeFile(String path, String content) {
    final normalizedPath = p.normalize(p.join(projectRoot, path));
    _createdFiles.add(normalizedPath);
    final file = resourceProvider.getFile(normalizedPath);
    Directory(p.dirname(normalizedPath)).createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  String readFile(String path) {
    final normalizedPath = p.normalize(p.join(projectRoot, path));
    return resourceProvider.getFile(normalizedPath).readAsStringSync();
  }

  Future<List<Diagnostic>> getLints({
    required String filePath,
    required ArchitectureLintRule lint,
  }) async {
    final absolutePath = p.normalize(p.join(projectRoot, filePath));
    final session = contextCollection.contextFor(absolutePath).currentSession;

    // --- THE CRITICAL FIX: Warm up the session BEFORE running the lint ---
    // The lint rule checks for entity supertypes, so it needs all related files resolved.
    final warmupFutures = _createdFiles
        .where((file) => file.endsWith('.dart'))
        .map((file) => session.getResolvedUnit(file))
        .toList();
    await Future.wait(warmupFutures);
    // --- END CRITICAL FIX ---

    final resolvedUnit = await session.getResolvedUnit(absolutePath) as ResolvedUnitResult;
    return lint.testRun(resolvedUnit);
  }

  Future<List<SourceChange>> getFixes(Diagnostic diagnostic, DartFix fix) async {
    final session = contextCollection.contextFor(diagnostic.source.fullName).currentSession;

    // --- THE DEFINITIVE FIX IS HERE ---
    // Just like with `getLints`, we must warm up the session before running the fix.
    // This ensures that when the fix's `run` method is called, it has access to
    // the fully resolved types of all related files.
    final warmupFutures = _createdFiles
        .where((file) => file.endsWith('.dart'))
        .map((file) => session.getResolvedUnit(file))
        .toList();
    await Future.wait(warmupFutures);

    // Now, get the final resolved unit for the file containing the diagnostic.
    final resolvedUnit = await session.getResolvedUnit(diagnostic.source.fullName) as ResolvedUnitResult;

    final prioritizedChanges = await fix.testRun(resolvedUnit, diagnostic, []);

    return prioritizedChanges.map((e) => e.change).toList();
  }
}