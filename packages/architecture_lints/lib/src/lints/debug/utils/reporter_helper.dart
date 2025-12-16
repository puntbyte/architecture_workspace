import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ReporterHelper {
  final DiagnosticReporter _reporter;
  final LintCode _code;

  ReporterHelper(this._reporter, this._code);

  void reportOnNode(AstNode node, String message) {
    _reporter.atNode(node, _code, arguments: [message]);
  }

  void reportOnToken(Token token, String message) {
    _reporter.atToken(token, _code, arguments: [message]);
  }

  void reportOnEntity(SyntacticEntity entity, String message) {
    _reporter.atEntity(entity, _code, arguments: [message]);
  }
}
