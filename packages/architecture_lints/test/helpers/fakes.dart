// test/helpers/fakes.dart

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

/// Fake implementation of [CustomLintContext].
/// Easier to use than a Mock because it holds real data state.
class FakeCustomLintContext extends Fake implements CustomLintContext {
  @override
  final Map<Object, Object?> sharedState = {};

  @override
  final Pubspec pubspec;

  FakeCustomLintContext({String packageName = 'test_project'}) : pubspec = Pubspec(packageName);
}

/// A Fake Builder to capture writes from the callback-based API.
class FakeDartEditBuilder extends Fake implements DartEditBuilder {
  final StringBuffer output = StringBuffer();

  @override
  void write(String string) {
    output.write(string);
  }

  @override
  void writeln([String? string]) {
    output.writeln(string ?? '');
  }
}

/// A Fake File Builder that supports both simple and callback-based edits.
class FakeDartFileEditBuilder extends Fake implements DartFileEditBuilder {
  final StringBuffer output = StringBuffer();

  // Track where the edit happened
  int? insertionOffset;
  SourceRange? replacementRange;

  // --- Callback-based methods (Used by your ArchitectureFix) ---

  @override
  void addReplacement(SourceRange range, void Function(DartEditBuilder builder) buildEdit) {
    replacementRange = range;
    final builder = FakeDartEditBuilder();
    buildEdit(builder);
    output.write(builder.output.toString());
  }

  @override
  void addInsertion(int offset, void Function(DartEditBuilder builder) buildEdit) {
    insertionOffset = offset;
    final builder = FakeDartEditBuilder();
    buildEdit(builder);
    output.write(builder.output.toString());
  }

  // --- Simple methods (Legacy/Fallback support) ---

  @override
  void addSimpleReplacement(SourceRange range, String text) {
    replacementRange = range;
    output.write(text);
  }

  @override
  void addSimpleInsertion(int offset, String text) {
    insertionOffset = offset;
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

class FakeLintCode extends Fake implements LintCode {}

class FakePubspec extends Fake implements Pubspec {
  @override
  final String name;

  FakePubspec({this.name = 'test_project'});
}

class FakeSource extends Fake implements Source {
  @override
  final String fullName;

  FakeSource({required this.fullName});
}

class FakeToken extends Fake implements Token {
  @override
  final int offset;

  @override
  final int length;

  FakeToken({this.offset = 0, this.length = 0});

  @override
  TokenType get type => TokenType.IDENTIFIER;
}
