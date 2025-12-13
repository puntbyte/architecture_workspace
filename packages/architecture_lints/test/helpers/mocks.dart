// test/helpers/mocks.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as analyzer_error;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';

import 'fakes.dart';

class MockCustomLintContext extends Mock implements CustomLintContext {
  @override
  Pubspec get pubspec => FakePubspec();
}

class MockChangeReporter extends Mock implements ChangeReporter {}
class MockChangeBuilder extends Mock implements ChangeBuilder {}
class MockCustomLintResolver extends Mock implements CustomLintResolver {}
class MockDiagnostic extends Mock implements Diagnostic {}
class MockLintCode extends Mock implements analyzer_error.LintCode {}

class MockDiagnosticMessage extends Mock implements DiagnosticMessage {}


class MockDiagnosticReporter extends Mock implements DiagnosticReporter {}

class MockLintRuleNodeRegistry extends Mock implements LintRuleNodeRegistry {}

class MockAnalysisError extends Mock implements Diagnostic {}

/// Resolves Dart source code into a [ResolvedUnitResult] for testing.
Future<ResolvedUnitResult> resolveContent(String content) async {
  final tempDir = Directory.systemTemp.createTempSync('arch_lint_test_');
  try {
    final file = File(p.join(tempDir.path, 'lib', 'test.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    final result = await resolveFile(path: p.normalize(file.absolute.path));
    if (result is! ResolvedUnitResult) {
      throw StateError('Failed to resolve test file');
    }
    return result;
  } finally {
    // In a real test runner, you might want to keep this until tearDown
    // For this helper, we assume immediate usage.
    // If you need it to persist, move deletion to the test tearDown.
  }
}


/// Fake implementation of [CustomLintContext].
/// Easier to use than a Mock because it holds real data state.
class FakeCustomLintContext extends Fake implements CustomLintContext {
  @override
  final Map<Object, Object?> sharedState = {};

  @override
  final Pubspec pubspec;

  FakeCustomLintContext({String packageName = 'test_project'})
      : pubspec = Pubspec(packageName);
}

class FakeDartFileEditBuilder extends Fake implements DartFileEditBuilder {
  final StringBuffer output = StringBuffer();

  @override
  void addSimpleReplacement(SourceRange range, String text) {
    output.write(text);
  }

  @override
  void addSimpleInsertion(int offset, String text) {
    output.write(text);
  }
}

class FakeDiagnosticMessage extends Fake implements DiagnosticMessage {
  final String _message;

  FakeDiagnosticMessage(this._message);

  // Implement the method signature expected by the Analyzer
  @override
  String messageText({required bool includeUrl}) => _message;

  @override
  String get filePath => '/test/path.dart';

  @override
  int get offset => 0;

  @override
  int get length => 0;
}