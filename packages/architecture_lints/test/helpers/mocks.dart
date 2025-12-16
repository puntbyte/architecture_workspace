// test/helpers/mocks.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as analyzer_error;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'fakes.dart';

class MockAnalysisError extends Mock implements Diagnostic {}

class MockArchitectureConfig extends Mock implements ArchitectureConfig {}

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

class MockFileResolver extends Mock implements FileResolver {}



class MockLintCode extends Mock implements analyzer_error.LintCode {}

class MockLintRuleNodeRegistry extends Mock implements LintRuleNodeRegistry {}
