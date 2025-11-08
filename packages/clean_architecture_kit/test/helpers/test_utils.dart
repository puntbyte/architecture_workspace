// test/helpers/test_utils.dart

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/expect.dart';

/// A test implementation of the LintRuleNodeRegistry that allows us to
/// manually trigger visitors after the `run` method has been called.
class TestLintRuleNodeRegistry implements LintRuleNodeRegistry {
  void Function(FormalParameterList)? _formalParameterListCb;
  void Function(MethodDeclaration)? _methodDeclarationCb;
  void Function(FieldDeclaration)? _fieldDeclarationCb;

  @override
  void addFormalParameterList(void Function(FormalParameterList) cb) {
    _formalParameterListCb = cb;
  }

  @override
  void addMethodDeclaration(void Function(MethodDeclaration) cb) {
    _methodDeclarationCb = cb;
  }

  @override
  void addFieldDeclaration(void Function(FieldDeclaration) cb) {
    _fieldDeclarationCb = cb;
  }

  // Public method to manually trigger the visitor.
  void runFormalParameterList(FormalParameterList node) {
    _formalParameterListCb?.call(node);
  }

  // Public method to manually trigger the visitor.
  void runMethodDeclaration(MethodDeclaration node) {
    _methodDeclarationCb?.call(node);
  }

  // Public method to manually trigger the visitor.
  void runFieldDeclaration(FieldDeclaration node) {
    _fieldDeclarationCb?.call(node);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Prevents "missing implementation" errors for unused `add...` methods.
  }
}

/// A helper to create a LintContext with a test registry.
CustomLintContext makeContext(TestLintRuleNodeRegistry registry) {
  return CustomLintContext(
    registry,
    (cb) => cb(), // Mocked addPostRunCallback
    <Object, Object?>{}, // Mocked sharedState
    null,
  );
}

// test/helpers/test_utils.dart

// A simple helper extension to make test assertions cleaner.
extension ResolvedUnitResultExt on Future<ResolvedUnitResult> {
  /// Asserts that the resolved unit has an error with the given [code]
  /// and that the highlighted portion of the error contains the string [at].
  Future<void> withError(LintCode code, {required String at}) async {
    final result = await this;
    final errors = result.errors;

    expect(errors, isNotEmpty, reason: 'Expected to find lints, but found none.');

    final matchingError = errors.firstWhere(
      (e) => e.errorCode.name == code.name,
      orElse: () => throw StateError('No lint found with code ${code.name}'),
    );

    final highlightedText = result.content.substring(
      matchingError.offset,
      matchingError.offset + matchingError.length,
    );
    expect(highlightedText, contains(at));
  }

  /// Asserts that the resolved unit has no lint errors.
  Future<void> withNoIssues() async {
    final result = await this;
    expect(
      result.errors,
      isEmpty,
      reason: 'Expected no issues, but found ${result.errors.length}.',
    );
  }
}

