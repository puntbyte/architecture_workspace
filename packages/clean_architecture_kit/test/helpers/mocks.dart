// test/helpers/mocks.dart

import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';

class MockCustomLintContext extends Mock implements CustomLintContext {}

class MockCustomLintResolver extends Mock implements CustomLintResolver {}

class MockDiagnosticReporter extends Mock implements DiagnosticReporter {}

class MockLintRuleNodeRegistry extends Mock implements LintRuleNodeRegistry {}
