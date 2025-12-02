// test/helpers/fakes.dart

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

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
