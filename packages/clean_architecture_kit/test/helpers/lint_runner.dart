// test/helpers/lint_runner.dart
import 'dart:async';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/error/error.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

/// A powerful test utility to run a single lint rule on a piece of source code.
///
/// Returns a list of all lint messages found by the specified rule.
Future<List<AnalysisError>> runLint(
    String source,
    CleanArchitectureLintRule lint, {
      String path = '/my_project/lib/features/auth/domain/contracts/repo.dart',
    }) async {
  // 1. Parse the source code into a full AST with resolved types.
  final parseResult = await resolveSources(
    [path],
        (resolver) async => resolver.resolveUrl(path),
    sourceResolver: (uri) {
      if (uri.path == path) {
        return MemorySource(source, uri);
      }
      // Provide dummy content for any other imports to prevent analysis errors.
      return MemorySource('// Dummy source for $uri', uri);
    },
  );

  final errors = <AnalysisError>[];
  final listener = ErrorListener((error) => errors.add(error));
  final reporter = DiagnosticReporter(listener, parseResult.source);

  // 2. Set up the context and registry for the lint.
  final registry = LintRuleNodeRegistry(NodeLintRegistry(false), lint.code.name);
  final context = CustomLintContext(
    registry,
        (cb) => cb(),
    {},
    Pubspec.fromMap({'name': 'my_project'}),
  );

  // 3. Create a fake resolver that only provides the path.
  final resolver = FakeCustomLintResolver(path: path);

  // 4. Run the lint's `run` method to register its visitors.
  lint.run(resolver, reporter, context);

  // 5. Trigger the visitors by walking the parsed AST.
  parseResult.unit.accept(registry.visitor);

  return errors;
}

// Minimal fakes required by the runner.
class FakeCustomLintResolver implements CustomLintResolver {
  @override
  final String path;
  FakeCustomLintResolver({required this.path});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ErrorListener extends AnalysisErrorListener {
  final void Function(AnalysisError) _onError;
  ErrorListener(this._onError);
  @override
  void onError(AnalysisError error) => _onError(error);
}