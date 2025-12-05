import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/enums/member_kind.dart';
import 'package:architecture_lints/src/config/enums/member_modifier.dart';
import 'package:architecture_lints/src/config/enums/member_visibility.dart';
import 'package:architecture_lints/src/config/schema/member_constraint.dart';

mixin MemberLogic {
  bool matchesConstraint(ClassMember member, MemberConstraint constraint) {
    final element = _getElement(member);
    if (element == null) return false;

    // 1. Kind Match
    if (constraint.kind != null) {
      final kind = _getKind(member);
      // 'overrideKind' is a special case check for annotation
      if (constraint.kind == MemberKind.overrideKind) {
        if (!_hasOverrideAnnotation(member)) return false;
      } else if (kind != constraint.kind) {
        return false;
      }
    }

    // 2. Visibility Match
    if (constraint.visibility != null) {
      final isPublic = !element.isPrivate;
      if (constraint.visibility == MemberVisibility.public && !isPublic) return false;
      if (constraint.visibility == MemberVisibility.private && isPublic) return false;
    }

    // 3. Modifier Match
    if (constraint.modifier != null) {
      if (!_hasModifier(member, element, constraint.modifier!)) return false;
    }

    // 4. Identifier Match
    if (constraint.identifiers.isNotEmpty) {
      final name = element.name;
      if (name == null) return false;

      var idMatch = false;
      for (final pattern in constraint.identifiers) {
        if (RegExp(pattern).hasMatch(name)) {
          idMatch = true;
          break;
        }
      }
      if (!idMatch) return false;
    }

    return true;
  }

  Element? _getElement(ClassMember member) {
    if (member is MethodDeclaration) return member.declaredFragment?.element;
    if (member is FieldDeclaration) return member.fields.variables.first.declaredFragment?.element;
    if (member is ConstructorDeclaration) return member.declaredFragment?.element;
    return null;
  }

  MemberKind? _getKind(ClassMember member) {
    if (member is ConstructorDeclaration) return MemberKind.constructor;
    if (member is MethodDeclaration) {
      if (member.isGetter) return MemberKind.getter;
      if (member.isSetter) return MemberKind.setter;
      return MemberKind.method;
    }
    if (member is FieldDeclaration) return MemberKind.field;
    return null;
  }

  bool _hasOverrideAnnotation(ClassMember member) {
    return member.metadata.any((a) => a.name.name == 'override');
  }

  bool _hasModifier(ClassMember member, Element element, MemberModifier modifier) {
    switch (modifier) {
      case MemberModifier.staticMod:
        if (element is ExecutableElement) return element.isStatic;
        if (element is FieldElement) return element.isStatic;
        return false;
      case MemberModifier.finalMod:
        if (element is FieldElement) return element.isFinal;
        return false;
      case MemberModifier.constMod:
        if (element is FieldElement) return element.isConst;
        if (element is ConstructorElement) return element.isConst;
        return false;
      case MemberModifier.lateMod:
        if (element is FieldElement) return element.isLate;
        return false;
    }
  }
}
