// lib/src/engines/expression/wrappers/node_wrapper.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/engines/expression/expression.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/class_wrapper.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:expressions/expressions.dart' hide Identifier;

class NodeWrapper {
  final AstNode? node;
  final Map<String, TypeDefinition> definitions;

  const NodeWrapper(
    this.node, {
    this.definitions = const {},
  });

  // Constructor for wrappers that don't have a source AST node (e.g. FieldElement)
  const NodeWrapper.withoutNode({
    this.definitions = const {},
  }) : node = null;

  factory NodeWrapper.create(AstNode node, [Map<String, TypeDefinition> definitions = const {}]) {
    if (node is ClassDeclaration) return ClassWrapper(node, definitions: definitions);
    if (node is MethodDeclaration) return MethodWrapper(node, definitions: definitions);
    if (node is FormalParameter) return ParameterWrapper(node, definitions: definitions);

    if (node is VariableDeclaration) return FieldWrapper(node, definitions: definitions);
    if (node is FieldDeclaration && node.fields.variables.isNotEmpty) {
      return FieldWrapper(node.fields.variables.first, definitions: definitions);
    }

    return NodeWrapper(node, definitions: definitions);
  }

  static MemberAccessor<NodeWrapper> get accessor =>
      const MemberAccessor<NodeWrapper>.fallback(getMember);

  static dynamic getMember(NodeWrapper obj, String name) => switch (name) {
    'name' => obj.name,
    'parent' => obj.parent,
    'file' => {'path': obj.filePath},
    'filePath' => obj.filePath,
    _ => throw ArgumentError('Property "$name" not found on ${obj.runtimeType}'),
  };

  StringWrapper get name {
    String? id;
    final n = node;

    if (n != null) {
      if (n is Declaration) id = n.declaredFragment?.element.name;

      if (id == null) {
        if (n is MethodDeclaration) id = n.name.lexeme;
        if (n is ClassDeclaration) id = n.name.lexeme;
        if (n is Identifier) id = n.name;
        if (n is VariableDeclaration) id = n.name.lexeme;
      }
    }

    return StringWrapper(id ?? '');
  }

  StringWrapper get filePath {
    if (node == null) return const StringWrapper('');
    final root = node!.root;
    if (root is CompilationUnit) {
      final source = root.declaredFragment?.source;
      return StringWrapper(source?.fullName ?? '');
    }
    return const StringWrapper('');
  }

  NodeWrapper? get parent => (node != null && node!.parent != null)
      ? NodeWrapper.create(node!.parent!, definitions)
      : null;

  @override
  String toString() => name.value;

  Map<String, dynamic> toMap() => {
    // Convert wrapper fields to plain maps/primitives for templates
    'name': name.toMap(),
    'parent': parent?.toMap(),
    'file': {'path': filePath.value},
  };
}
