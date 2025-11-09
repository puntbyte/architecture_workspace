// test/helpers/fakes.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';

// A minimal fake for LintCode.
class FakeLintCode extends Fake implements LintCode {}

// A minimal fake for Source.
class FakeSource extends Fake implements Source {
  @override
  final String fullName;
  FakeSource({required this.fullName});
}

// A minimal fake for SourceRange.
class FakeSourceRange extends Fake implements SourceRange {}

class FakeToken extends Fake implements Token {}
