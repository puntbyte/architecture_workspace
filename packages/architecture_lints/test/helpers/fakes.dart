import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' as analyzer_error;
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

/// Fake implementation of [CustomLintContext].
/// Easier to use than a Mock because it holds real shared state map.
class FakeCustomLintContext extends Fake implements CustomLintContext {
  @override
  final Map<Object, Object?> sharedState = {};

  @override
  final Pubspec pubspec;

  FakeCustomLintContext({String packageName = 'test_project'}) : pubspec = Pubspec(packageName);
}

/// A Fake Builder to capture edits requested by ArchitectureFix.
/// Allows assertions like: expect(builder.output.toString(), contains('class User'))
class FakeDartFileEditBuilder extends Fake implements DartFileEditBuilder {
  final StringBuffer output = StringBuffer();

  // Tracks the last replacement range for verification
  SourceRange? lastReplacementRange;
  int? lastInsertionOffset;

  @override
  void addSimpleReplacement(SourceRange range, String text) {
    lastReplacementRange = range;
    output.write(text);
  }

  @override
  void addSimpleInsertion(int offset, String text) {
    lastInsertionOffset = offset;
    output.write(text);
  }

  void write(String code) {
    output.write(code);
  }
}

class FakeLintCode extends Fake implements analyzer_error.LintCode {
  @override
  String get name => 'fake_code';
}

/// Fake implementation of Token for when we need to report on a specific token location.
class FakeToken extends Fake implements Token {
  @override
  final int offset;

  @override
  final int length;

  @override
  final String lexeme;

  FakeToken({this.offset = 0, this.length = 0, this.lexeme = 'test_token'});

  @override
  TokenType get type => TokenType.IDENTIFIER;
}
