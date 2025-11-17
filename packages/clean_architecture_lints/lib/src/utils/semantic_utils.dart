// lib/src/utils/semantic_utils.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';

/// A utility class for common semantic analysis tasks related to the element model.
class SemanticUtils {
  const SemanticUtils._();

  /// Checks if an executable element is an architectural override of a contract.
  ///
  /// An architectural override means the element implements or extends a member
  /// from a class that is defined in a domain 'contract' directory.
  static bool isArchitecturalOverride(ExecutableElement element, LayerResolver layerResolver) {
    final enclosingClass = element.enclosingElement;
    if (enclosingClass is! InterfaceElement) return false;

    final elementName = element.name;
    if (elementName == null) return false;

    // Check all supertypes to see if any of them is a domain contract
    // that declares a member with the same name.
    for (final supertype in enclosingClass.allSupertypes) {
      final source = supertype.element.firstFragment.libraryFragment.source;

      if (layerResolver.getComponent(source.fullName) == ArchComponent.contract) {
        if (supertype.getMethod(elementName) != null || supertype.getGetter(elementName) != null) {
          return true;
        }
      }
    }
    return false;
  }

  /// Recursively checks if a type or any of its generic arguments is from Flutter.
  static bool isFlutterType(DartType? type) {
    if (type == null) return false;

    final library = type.element?.library;
    if (library != null) {
      final uri = library.uri;
      final isFlutterPackage =
          uri.isScheme('package') &&
              uri.pathSegments.isNotEmpty &&
              uri.pathSegments.first == 'flutter';
      final isDartUi =
          uri.isScheme('dart') && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'ui';
      if (isFlutterPackage || isDartUi) return true;
    }

    // Recurse on generic type arguments (e.g., List<Color>).
    if (type is InterfaceType) {
      return type.typeArguments.any(isFlutterType);
    }
    return false;
  }

  /// Recursively checks if a type or any of its generic arguments is a specific
  /// architectural component by its file location.
  static bool isComponent(
      DartType? type,
      LayerResolver layerResolver,
      ArchComponent componentToFind,
      ) {
    if (type == null) return false;

    // Check the primary type itself.
    final source = type.element?.firstFragment.libraryFragment?.source;
    if (source != null) {
      if (layerResolver.getComponent(source.fullName) == componentToFind) {
        return true;
      }
    }

    // Recurse on generic type arguments (e.g., List<UserModel>).
    if (type is InterfaceType) {
      return type.typeArguments.any((arg) => isComponent(arg, layerResolver, componentToFind));
    }
    return false;
  }
}
