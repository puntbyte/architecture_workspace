// test/helpers/mocks.dart

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as analyzer_error;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'fakes.dart';

class MockAnalysisError extends Mock implements Diagnostic {}

class MockChangeBuilder extends Mock implements ChangeBuilder {}

class MockChangeReporter extends Mock implements ChangeReporter {}

class MockCustomLintContext extends Mock implements CustomLintContext {
  @override
  Pubspec get pubspec => FakePubspec();
}

class MockCustomLintResolver extends Mock implements CustomLintResolver {}

class MockDiagnostic extends Mock implements Diagnostic {}

class MockDiagnosticMessage extends Mock implements DiagnosticMessage {}

class MockDiagnosticReporter extends Mock implements DiagnosticReporter {}

class MockLintCode extends Mock implements analyzer_error.LintCode {}

class MockLintRuleNodeRegistry extends Mock implements LintRuleNodeRegistry {}
