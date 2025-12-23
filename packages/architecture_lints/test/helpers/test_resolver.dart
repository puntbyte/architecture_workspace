import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' as p;

/// Creates a temporary file with [content] and resolves it using the real Analyzer.
///
/// This mimics how the linter sees code in a real project.
Future<ResolvedUnitResult> resolveContent(String content) async {
  // 1. Create a unique temp directory
  final tempDir = Directory.systemTemp.createTempSync('arch_lint_test_');

  try {
    // 2. Create the Dart file
    final filePath = p.normalize(p.join(tempDir.path, 'lib', 'test.dart'));
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);

    // 3. Create a minimal pubspec.yaml
    // The analyzer requires this to understand 'package:' URIs and project structure.
    File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
    name: test_project
    environment:
      sdk: '>=3.0.0 <4.0.0'
    ''');

    // 4. Run the Analyzer
    final collection = AnalysisContextCollection(includedPaths: [tempDir.path]);
    final context = collection.contextFor(filePath);
    final result = await context.currentSession.getResolvedUnit(filePath);

    if (result is ResolvedUnitResult) {
      return result;
    }

    throw StateError('Failed to resolve content. Result type: ${result.runtimeType}');
  } catch (e) {
    // Cleanup on error (optional, OS handles temp eventually)
    // tempDir.deleteSync(recursive: true);
    rethrow;
  }
}
