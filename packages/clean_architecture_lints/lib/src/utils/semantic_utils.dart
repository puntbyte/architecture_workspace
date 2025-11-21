// lib/src/utils/semantic_utils.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';

/// A utility class for common semantic analysis tasks related to the element model.
class SemanticUtils {
  const SemanticUtils._();

  /// Checks if an executable element is an override of a member from an
  /// architectural contract (a Port). This is the definitive check.
  static bool isArchitecturalOverride(ExecutableElement element, LayerResolver layerResolver) {
    final enclosingClass = element.enclosingElement;
    if (enclosingClass is! InterfaceElement) return false;
    if (element.isStatic || element.name == null) return false;

    // Iterate through all interfaces and superclasses this class implements or extends.
    for (final supertype in enclosingClass.allSupertypes) {
      final supertypeElement = supertype.element;
      final sourcePath = supertypeElement.library.firstFragment.source.fullName;

      // Check if this supertype is defined in a "port" file.
      if (layerResolver.getComponent(sourcePath) == ArchComponent.port) {
        // Check if the Port interface itself DIRECTLY DECLARES a member with the same name.
        if (element is MethodElement && supertypeElement.methods.any((m) => m.name == element.name)) {
          return true;
        }
        // FIX: Check `getters` and `setters` lists separately, as `accessors` does not exist.
        if (element is PropertyAccessorElement) {
          if (supertypeElement.getters.any((g) => g.name == element.name) ||
              supertypeElement.setters.any((s) => s.name == element.name)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Recursively checks if a type or any of its generic arguments is from Flutter.
  static bool isFlutterType(DartType? type) {
    if (type == null) return false;
    final uri = type.element?.library?.firstFragment.source.uri;
    if (uri != null) {
      final isFlutterPackage = uri.isScheme('package') && uri.pathSegments.firstOrNull == 'flutter';
      final isDartUi = uri.isScheme('dart') && uri.pathSegments.firstOrNull == 'ui';
      if (isFlutterPackage || isDartUi) return true;
    }
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
    final path = _getSourcePath(type);
    if (path != null && layerResolver.getComponent(path) == componentToFind) return true;
    if (type is InterfaceType) {
      return type.typeArguments.any((arg) => isComponent(arg, layerResolver, componentToFind));
    }
    return false;
  }

  static String? _getSourcePath(DartType? type) {
    return type?.element?.library?.firstFragment.source.fullName;
  }
}
