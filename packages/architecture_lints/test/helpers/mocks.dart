import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as analyzer_error;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/engines/file/file.dart';
import 'package:architecture_lints/src/engines/template/template.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';

// --- Analyzer & Lint Mocks ---

class MockCustomLintResolver extends Mock implements CustomLintResolver {}

class MockChangeReporter extends Mock implements ChangeReporter {}

class MockChangeBuilder extends Mock implements ChangeBuilder {}

class MockDiagnostic extends Mock implements Diagnostic {}

class MockDiagnosticReporter extends Mock implements DiagnosticReporter {}

class MockLintCode extends Mock implements analyzer_error.LintCode {}

// --- Engine Mocks ---

class MockFileResolver extends Mock implements FileResolver {}

class MockTemplateLoader extends Mock implements TemplateLoader {}
