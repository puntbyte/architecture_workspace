import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/engines/file/file.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';

/// Defines which aspects of a DartType to check against a Definition.
enum TypeCheckMode {
  /// Checks both the Alias (typedef) and the Canonical (underlying) type.
  any,
  /// Checks ONLY the Canonical element (e.g. 'int' in 'typedef Id = int').
  canonical,
  /// Checks ONLY the Alias element (e.g. 'Id' in 'typedef Id = int').
  alias,
}

class TypeResolver {
  final Map<String, TypeDefinition> registry;
  final FileResolver fileResolver;

  const TypeResolver({
    required this.registry,
    required this.fileResolver,
  });

  /// Checks if [type] matches the [definition] using the specified [mode].
  bool matches(
      DartType? type,
      TypeDefinition definition, {
        TypeCheckMode mode = TypeCheckMode.any,
      }) {
    if (type == null) return false;

    // 1. Check Wildcard
    if (definition.isWildcard) return true;

    // 2. Check Reference (Recursive)
    if (definition.ref != null) {
      final refDef = registry[definition.ref];
      if (refDef == null) return false;
      return matches(type, refDef, mode: mode);
    }

    // 3. Check Component Location
    if (definition.component != null) {
      if (_matchesComponent(type, definition.component!)) {
        return true;
      }
    }

    // 4. Element Checks

    // Mode: Canonical or Any
    if (mode == TypeCheckMode.canonical || mode == TypeCheckMode.any) {
      if (_matchesElement(type.element, definition, type)) {
        return true;
      }
    }

    // Mode: Alias or Any
    if (mode == TypeCheckMode.alias || mode == TypeCheckMode.any) {
      if (type.alias != null) {
        if (_matchesElement(type.alias!.element, definition, type)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _matchesElement(Element? element, TypeDefinition def, DartType originalType) {
    if (element == null) {
      if (originalType is VoidType && def.types.contains('void')) return true;
      if (originalType is DynamicType && def.types.contains('dynamic')) return true;
      return false;
    }

    final name = element.name;
    if (name == null) return false;

    // A. Check Name
    if (def.types.isNotEmpty && !def.types.contains(name)) {
      return false;
    }

    // B. Check Import
    if (def.imports.isNotEmpty) {
      final lib = element.library;
      final uri = lib?.firstFragment.source.uri.toString();

      if (uri == 'dart:core' && def.imports.contains('dart:core')) return true;

      if (uri == null) return false;

      final importMatch = def.imports.any((i) => uri == i || uri.startsWith(i));
      if (!importMatch) return false;
    }

    // C. Check Generics
    if (def.arguments.isNotEmpty) {
      final typeArgs = _getTypeArguments(originalType);

      if (typeArgs.length < def.arguments.length) return false;

      for (var i = 0; i < def.arguments.length; i++) {
        final argDef = def.arguments[i];
        final actualArg = typeArgs[i];

        // For generics, we typically want to match ANY valid definition (alias or canonical)
        // unless we want strict recursion. Defaulting to .any is safer for nested types.
        if (!matches(actualArg, argDef, mode: TypeCheckMode.any)) {
          return false;
        }
      }
    }

    return true;
  }

  bool _matchesComponent(DartType type, String componentId) {
    final element = type.element;
    if (element == null) return false;

    final library = element.library;
    if (library == null) return false;

    final sourcePath = library.firstFragment.source.fullName;
    final component = fileResolver.resolve(sourcePath);

    if (component != null) {
      return component.matchesReference(componentId);
    }
    return false;
  }

  bool matchesComponent(DartType type, String componentId) {
    return _matchesComponent(type, componentId);
  }

  List<DartType> _getTypeArguments(DartType type) {
    if (type is InterfaceType) return type.typeArguments;
    if (type.alias != null) return type.alias!.typeArguments;
    return [];
  }
}