// test/helpers/test_resolver.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' as p;

/// Creates a temporary file with [content] and resolves it using the real Analyzer.
Future<ResolvedUnitResult> resolveContent(String content) async {
  final tempDir = Directory.systemTemp.createTempSync('arch_fix_test_');
  try {
    final filePath = p.normalize(p.join(tempDir.path, 'lib', 'test.dart'));
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);

    // Create minimal pubspec so package resolution works
    File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('name: test_project');

    final collection = AnalysisContextCollection(includedPaths: [tempDir.path]);
    final context = collection.contextFor(filePath);
    final result = await context.currentSession.getResolvedUnit(filePath);

    if (result is ResolvedUnitResult) {
      return result;
    }
    throw StateError('Failed to resolve content: $result');
  } catch (e) {
    rethrow;
  }
  // Note: We leave tempDir cleanup to the OS or tearDown in the test to avoid race conditions.
}
