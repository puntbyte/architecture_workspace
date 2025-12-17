// lib/src/engines/expression/wrappers/class_wrapper.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/engines/expression/expression.dart';
import 'package:expressions/expressions.dart';

class ClassWrapper extends NodeWrapper {
  final ClassDeclaration classNode;

  const ClassWrapper(
    this.classNode, {
    super.definitions = const {},
  }) : super(classNode);

  static MemberAccessor<ClassWrapper> get accessor =>
      const MemberAccessor<ClassWrapper>.fallback(_getMember);

  static dynamic _getMember(ClassWrapper obj, String name) => switch (name) {
    'fields' => obj.fields,
    _ => NodeWrapper.getMember(obj, name),
  };

  /// Returns all fields (including those defined in constructors).
  ListWrapper<FieldWrapper> get fields {
    final element = classNode.declaredFragment?.element;
    if (element == null) return const ListWrapper([]);

    // We use the Element API because it unifies fields defined in body
    // and fields defined in constructor (this.field).
    // We filter out synthetic fields (like 'hashCode') and static fields if needed.
    final allFields = element.fields
        .where((f) => !f.isSynthetic && !f.isStatic)
        .map((f) => FieldWrapper.fromElement(f, definitions: definitions))
        .toList();

    return ListWrapper(allFields);
  }

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()..addAll({
      'fields': fields, // ListWrapper handles mapping in expression engine
    });
  }
}
