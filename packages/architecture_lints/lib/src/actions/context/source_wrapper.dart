import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:recase/recase.dart';

/// Wraps an AST Node to expose properties to the expression engine.
/// e.g. source.name.pascalCase
class SourceWrapper {
  final AstNode node;
  final Element? element;

  SourceWrapper(this.node)
      : element = (node is Declaration) ? node.declaredFragment?.element : null;

  String get name {
    if (node is Declaration) {
      final id = (node as Declaration).declaredFragment?.element.name;
      return id ?? '';
    }
    return '';
  }

  // Expose Parent
  SourceWrapper? get parent => node.parent != null ? SourceWrapper(node.parent!) : null;

  // Expose ReCase extensions directly
  String get pascalCase => ReCase(name).pascalCase;
  String get snakeCase => ReCase(name).snakeCase;
  String get camelCase => ReCase(name).camelCase;

  // Expose Lists (for parameters)
  List<SourceWrapper> get parameters {
    if (node is FunctionExpression) {
      return (node as FunctionExpression).parameters?.parameters
          .map(SourceWrapper.new).toList() ?? [];
    }
    if (node is MethodDeclaration) {
      return (node as MethodDeclaration).parameters?.parameters
          .map(SourceWrapper.new).toList() ?? [];
    }
    return [];
  }

  // Properties for Parameters
  String get type {
    if (node is FormalParameter) {
      return (node as FormalParameter).declaredFragment?.element.type.getDisplayString() ?? '';
    }
    return '';
  }

  bool get isNamed => node is FormalParameter && (node as FormalParameter).isNamed;

  @override
  String toString() => name;
}