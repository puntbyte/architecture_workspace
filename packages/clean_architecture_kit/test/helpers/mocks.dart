// test/helpers/mocks.dart

import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';

class MockCustomLintContext extends Mock implements CustomLintContext {}

class MockCustomLintResolver extends Mock implements CustomLintResolver {}

class MockDiagnosticReporter extends Mock implements DiagnosticReporter {}

class MockLintRuleNodeRegistry extends Mock implements LintRuleNodeRegistry {}

/*
// --- Core Mocks ---
class MockDiagnosticReporter extends Mock implements DiagnosticReporter {}

// --- Element Mocks ---
class MockMethodElement extends Mock implements MethodElement {}
class MockClassElement extends Mock implements ClassElement {}
class MockLibraryElement extends Mock implements LibraryElement {}

// --- Type Mocks ---
class MockInterfaceType extends Mock implements InterfaceType {}

class MockCustomLintResolver extends Mock implements CustomLintResolver {}

class MockSource extends Mock implements Source {}


class FakeToken extends Fake implements Token {}

class FakeLintCode extends Fake implements LintCode {}

class MockCustomLintContext extends Mock implements CustomLintContext {}

class MockRegistry extends Mock implements LintRuleNodeRegistry {}*/
