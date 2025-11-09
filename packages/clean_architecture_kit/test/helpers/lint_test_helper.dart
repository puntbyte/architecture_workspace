// test/helpers/lint_test_helper.dart
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'fakes.dart';
import 'mocks.dart';

/// A generic helper to run any lint rule on a given source file.
///
/// It mocks the custom_lint framework, parses the source, and invokes the
/// lint's visitor on the appropriate AST node.
Future<void> runLint<T extends AstNode>(
  String source,
  String path,
  DartLintRule lint,
  MockDiagnosticReporter reporter, {
  void Function(T node)? onNode,
}) async {
  final resolver = MockCustomLintResolver();
  final context = MockCustomLintContext();
  final registry = MockLintRuleNodeRegistry();

  when(() => resolver.source).thenReturn(FakeSource(fullName: path));
  when(() => context.registry).thenReturn(registry);

  // Dynamically capture the correct visitor function based on the node type T.
  void Function(T)? capturedCallback;
  if (T == ClassDeclaration) {
    when(() => registry.addClassDeclaration(any())).thenAnswer((invocation) {
      capturedCallback = invocation.positionalArguments.first as void Function(T);
    });
  } else if (T == MethodDeclaration) {
    // Add other types as needed
    when(() => registry.addMethodDeclaration(any())).thenAnswer((invocation) {
      capturedCallback = invocation.positionalArguments.first as void Function(T);
    });
  } // Add more else-if blocks for other AST node types you need to test.

  lint.run(resolver, reporter, context);

  final parseResult = parseString(content: source, path: path, throwIfDiagnostics: false);
  final node = parseResult.unit.declarations.whereType<T>().first;

  expect(
    capturedCallback,
    isNotNull,
    reason: 'The lint did not register a visitor for $T.',
  );

  // Allow the test to perform actions on the node if needed.
  onNode?.call(node);

  capturedCallback!(node);
}
