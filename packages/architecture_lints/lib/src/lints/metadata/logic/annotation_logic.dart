import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/schema/annotation_constraint.dart';

mixin AnnotationLogic {
  bool matchesConstraint(Annotation node, AnnotationConstraint constraint) {
    final element = node.element;

    String? name;
    String? uri;

    if (element is ConstructorElement) {
      // @Injectable() -> Injectable class
      name = element.enclosingElement.name;
      uri = element.library.firstFragment.source.uri.toString();
    } else if (element is PropertyAccessorElement) {
      // @override (getter)
      name = element.name;
      uri = element.library.firstFragment.source.uri.toString();
    } else if (element is ClassElement) {
      name = element.name;
      uri = element.library.firstFragment.source.uri.toString();
    } else {
      // Fallback to simple name from AST if unresolved
      name = node.name.name;
    }

    if (name == null) return false;

    // 1. Check Name
    if (constraint.types.contains(name)) {
      // 2. Check Import (Optional)
      if (constraint.import != null) {
        return uri == constraint.import;
      }
      return true;
    }

    return false;
  }

  String describeConstraint(AnnotationConstraint c) {
    return c.types.join(' or ');
  }
}
