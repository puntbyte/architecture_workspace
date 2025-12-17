// lib/src/engines/expression/wrappers/field_wrapper.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/engines/expression/expression.dart';
import 'package:expressions/expressions.dart';

/// Wraps a class field (VariableDeclaration) to expose name/type for templates.
/// Extends NodeWrapper so it integrates with existing Node-based logic.
class FieldWrapper extends NodeWrapper {
  final VariableDeclaration? variable;
  final FieldElement? element;

  const FieldWrapper(
    VariableDeclaration this.variable, {
    super.definitions = const {},
  }) : element = null,
       super(variable);

  const FieldWrapper.fromElement(
    this.element, {
    super.definitions = const {},
  }) : variable = null,
       super.withoutNode();

  static MemberAccessor<FieldWrapper> get accessor =>
      const MemberAccessor<FieldWrapper>.fallback(_getMember);

  static dynamic _getMember(FieldWrapper obj, String name) => switch (name) {
    'type' => obj.type,
    'isFinal' => obj.isFinal,
    'isConst' => obj.isConst,
    'isLate' => obj.isLate,
    'isStatic' => obj.isStatic,
    'hasInitializer' => obj.hasInitializer,
    _ => NodeWrapper.getMember(obj, name),
  };

  @override
  StringWrapper get name => StringWrapper(variable?.name.lexeme ?? element?.name ?? '');

  TypeWrapper get type {
    // 1. Try Element type (most reliable)
    final t = element?.type ?? variable?.declaredFragment?.element.type;
    if (t != null) {
      return TypeWrapper(t, definitions: definitions);
    }

    // 2. Try AST TypeAnnotation (only available if we have the node)
    if (variable != null) {
      final parent = variable!.parent;
      if (parent is VariableDeclarationList) {
        final typeAnnotation = parent.type;
        if (typeAnnotation != null) {
          return TypeWrapper(
            typeAnnotation.type,
            rawString: typeAnnotation.toSource(),
            definitions: definitions,
          );
        }
      }
    }

    return TypeWrapper(null, rawString: 'dynamic', definitions: definitions);
  }

  bool get isFinal => element?.isFinal ?? variable?.isFinal ?? false;
  bool get isConst => element?.isConst ?? variable?.isConst ?? false;
  bool get isLate => element?.isLate ?? variable?.isLate ?? false;
  bool get hasInitializer => element?.hasInitializer ?? variable?.initializer != null;

  bool get isStatic {
    if (element != null) return element!.isStatic;
    // Check AST parent for static keyword
    if (variable != null) {
      final parent = variable!.parent?.parent;
      if (parent is FieldDeclaration) return parent.isStatic;
    }
    return false;
  }

  @override
  Map<String, dynamic> toMap() {
    final base = super.toMap()
      ..addAll({
        'type': type,
        'isFinal': isFinal,
        'isConst': isConst,
        'isLate': isLate,
        'isStatic': isStatic,
        'hasInitializer': hasInitializer,
      });
    return base;
  }
}
