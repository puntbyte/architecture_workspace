import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';

mixin ExceptionLogic {
  bool matchesType(
    DartType? type,
    String? definitionKey,
    String? rawType,
    Map<String, Definition> registry,
  ) {
    if (type == null) return false;

    final element = type.element;

    // FIX: Remove (withNullability: false)
    final name = element?.name ?? type.getDisplayString();

    // 1. Raw Type Check
    if (rawType != null && name == rawType) return true;

    // 2. Definition Check
    if (definitionKey != null) {
      final def = registry[definitionKey];
      if (def != null) {
        if (def.types.contains(name)) {
          if (def.imports.isNotEmpty) {
            final libUri = element?.library?.firstFragment.source.uri.toString();
            // Handle dart:core exceptions
            if (libUri == 'dart:core' && def.imports.isEmpty) return true;

            if (libUri != null && def.imports.any(libUri.startsWith)) return true;

            return false;
          }
          return true;
        }
      }
    }
    return false;
  }

  List<T> findNodes<T extends AstNode>(AstNode root) {
    final results = <T>[];
    root.visitChildren(_TypedVisitor<T>(results));
    return results;
  }

  DartType? getCaughtType(CatchClause node) => node.exceptionType?.type;

  bool returnStatementMatchesType(
    ReturnStatement node,
    String definitionKey,
    Map<String, Definition> registry,
  ) {
    final expression = node.expression;
    if (expression == null) return false;

    final returnType = expression.staticType;

    if (matchesType(returnType, definitionKey, null, registry)) return true;

    if (returnType is InterfaceType) {
      for (final arg in returnType.typeArguments) {
        if (matchesType(arg, definitionKey, null, registry)) return true;
      }
    }

    return false;
  }
}

class _TypedVisitor<T extends AstNode> extends UnifyingAstVisitor<void> {
  final List<T> results;

  _TypedVisitor(this.results);

  @override
  void visitNode(AstNode node) {
    if (node is T) {
      results.add(node);
    }
    node.visitChildren(this);
  }
}
