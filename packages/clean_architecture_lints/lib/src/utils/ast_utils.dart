// lib/src/utils/ast_utils.dart

import 'package:analyzer/dart/ast/ast.dart';

/// A utility class for common AST (Abstract Syntax Tree) traversal tasks.
class AstUtils {
  const AstUtils._();

  /// A robust helper to get the `TypeAnnotation` AST node from any kind of `FormalParameter`.
  static TypeAnnotation? getParameterTypeNode(FormalParameter parameter) {
    // Handle all common, simple parameter types.
    if (parameter is SimpleFormalParameter) return parameter.type;
    if (parameter is FieldFormalParameter) return parameter.type;
    if (parameter is SuperFormalParameter) return parameter.type;

    // THE FIX: Add a specific check for function-typed parameters.
    // Their type information is on the `returnType` property of the node itself.
    if (parameter is FunctionTypedFormalParameter) return parameter.returnType;

    // Recurse into wrapped parameters (like those with default values).
    if (parameter is DefaultFormalParameter) return getParameterTypeNode(parameter.parameter);

    return null;
  }
}
