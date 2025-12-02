// test/helpers/mocks.dart

import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'fakes.dart';

class MockCustomLintContext extends Mock implements CustomLintContext {
  @override
  Pubspec get pubspec => FakePubspec();
}

class MockCustomLintResolver extends Mock implements CustomLintResolver {}

class MockDiagnosticReporter extends Mock implements DiagnosticReporter {}

class MockLintRuleNodeRegistry extends Mock implements LintRuleNodeRegistry {}
