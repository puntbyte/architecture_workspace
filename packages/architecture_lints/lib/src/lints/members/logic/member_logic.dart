// lib/src/lints/members/logic/member_logic.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/schema/constraints/member_constraint.dart';
import 'package:architecture_lints/src/schema/enums/member_kind.dart';
import 'package:architecture_lints/src/schema/enums/member_modifier.dart';
import 'package:architecture_lints/src/schema/enums/member_visibility.dart';

mixin MemberLogic {
  bool matchesConstraint(ClassMember member, MemberConstraint constraint) {
    final element = _getElement(member);
    if (element == null) return false;

    // 1. Kind Match
    if (constraint.kind != null) {
      final kind = _getKind(member);
      // 'overrideKind' is a special case check for annotation
      if (constraint.kind == MemberKind.override) {
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

    // 4. Identifier Match (Smart Matching)
    if (constraint.identifiers.isNotEmpty) {
      final name = element.name;
      if (name == null) return false;

      var idMatch = false;
      for (final pattern in constraint.identifiers) {
        // A. If pattern contains regex symbols, treat as Regex
        if (_isRegex(pattern)) {
          if (RegExp(pattern).hasMatch(name)) {
            idMatch = true;
            break;
          }
        }
        // B. Otherwise, treat as Strict Exact Match
        // This prevents 'id' from matching 'middleName'
        else {
          if (name == pattern) {
            idMatch = true;
            break;
          }
        }
      }
      if (!idMatch) return false;
    }

    return true;
  }

  /// Checks if the string contains characters that suggest it's a Regex
  /// (^, $, *, +, ?, ., |, brackets, parens, escapes)
  bool _isRegex(String str) => str.contains(RegExp(r'[\^\$\.\*\+\?\|\(\)\[\]\{\}\\]'));

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
    return member.metadata.any((annotation) => annotation.name.name == 'override');
  }

  bool _hasModifier(ClassMember member, Element element, MemberModifier modifier) {
    switch (modifier) {
      case MemberModifier.static$:
        if (element is ExecutableElement) return element.isStatic;
        if (element is FieldElement) return element.isStatic;
        return false;

      case MemberModifier.final$:
        if (element is FieldElement) return element.isFinal;
        return false;

      case MemberModifier.const$:
        if (element is FieldElement) return element.isConst;
        if (element is ConstructorElement) return element.isConst;
        return false;

      case MemberModifier.late$:
        if (element is FieldElement) return element.isLate;
        return false;
    }
  }
}
