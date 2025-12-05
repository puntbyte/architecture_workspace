import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/config/schema/type_definition.dart';
import 'package:architecture_lints/src/config/schema/type_safety_config.dart';
import 'package:architecture_lints/src/config/schema/type_safety_constraint.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';

mixin TypeSafetyLogic {
  /// Checks if [type] matches any constraint in the [constraintList].
  bool matchesAnyConstraint(
    DartType type,
    List<TypeSafetyConstraint> constraintList,
    FileResolver fileResolver,
    Map<String, TypeDefinition> typeRegistry,
  ) {
    return constraintList.any(
      (c) => matchesConstraint(type, c, fileResolver, typeRegistry),
    );
  }

  /// Checks if [type] is explicitly forbidden by the [configRule] for the given [kind].
  ///
  /// This is used by "Allowed" rules to check if a "Forbidden" rule already covers this case.
  /// If this returns true, the "Allowed" rule should stay silent to avoid double-jeopardy.
  bool isExplicitlyForbidden({
    required DartType type,
    required TypeSafetyConfig configRule,
    required String kind, // 'return' or 'parameter'
    required FileResolver fileResolver,
    required Map<String, TypeDefinition> typeRegistry,
    String? paramName, // For parameter checks
  }) {
    // 1. Filter constraints matching the kind (and paramName if applicable)
    final forbiddenConstraints = configRule.forbidden.where((c) {
      if (c.kind != kind) return false;

      if (kind == 'parameter') {
        // Reuse param matching logic inline or helper
        if (c.identifier != null && paramName != null) {
          return RegExp(c.identifier!).hasMatch(paramName);
        }
      }
      return true;
    }).toList();

    // 2. Check if type matches any forbidden constraint
    return matchesAnyConstraint(
      type,
      forbiddenConstraints,
      fileResolver,
      typeRegistry,
    );
  }

  bool matchesConstraint(
    DartType type,
    TypeSafetyConstraint constraint,
    FileResolver fileResolver,
    Map<String, TypeDefinition> typeRegistry,
  ) {
    // 1. Check Canonical Element (e.g. Future<T>)
    if (_matchesElement(
      type.element,
      constraint,
      typeRegistry,
      typeArguments: _getTypeArguments(type),
    )) {
      return true;
    }

    // 2. Check Type Alias (e.g. FutureEither<T>)
    // Analyzer resolves typedefs to their underlying type. We must explicitly check the alias.
    if (type.alias != null) {
      if (_matchesElement(
        type.alias!.element,
        constraint,
        typeRegistry,
        typeArguments: type.alias!.typeArguments,
      )) {
        return true;
      }
    }

    // 3. Component Match (e.g. is this type a 'data.model'?)
    if (constraint.component != null) {
      final library = type.element?.library;
      if (library != null) {
        // Access source safely via fragment
        final sourcePath = library.firstFragment.source.fullName;
        final comp = fileResolver.resolve(sourcePath);
        if (comp != null) {
          // Check if the resolved component matches the constraint
          if (comp.matchesReference(constraint.component!)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Helper to extract type arguments safely from various DartType implementations
  List<DartType> _getTypeArguments(DartType type) {
    if (type is InterfaceType) return type.typeArguments;
    // Add other types if needed (e.g. RecordType fields, FunctionType return/params)
    return [];
  }

  bool _matchesElement(
    Element? element,
    TypeSafetyConstraint constraint,
    Map<String, TypeDefinition> typeRegistry, {
    List<DartType> typeArguments = const [],
  }) {
    if (element == null) return false;
    final name = element.name;
    if (name == null) return false;

    String? libUri;
    final library = element.library;
    if (library != null) {
      libUri = library.firstFragment.source.uri.toString();
    }

    // 1. Raw Type Match (Shallow check)
    if (constraint.types.contains(name)) return true;

    // 2. Definition Match (Deep check with recursion)
    if (constraint.definitions.isNotEmpty) {
      for (final defId in constraint.definitions) {
        final def = typeRegistry[defId];
        if (def == null) continue;

        if (_matchesDefinitionRecursive(def, name, libUri, typeArguments, typeRegistry)) {
          return true;
        }
      }
    }

    return false;
  }

  /// The Recursive Matching Engine
  bool _matchesDefinitionRecursive(
    TypeDefinition def,
    String? elementName,
    String? elementUri,
    List<DartType> typeArgs,
    Map<String, TypeDefinition> registry,
  ) {
    // A. Handle Wildcard (*)
    if (def.isWildcard) return true;

    // B. Handle Reference (definition: 'failure.base')
    if (def.definitionReference != null) {
      final referencedDef = registry[def.definitionReference];
      if (referencedDef == null) return false; // Config error
      return _matchesDefinitionRecursive(
        referencedDef,
        elementName,
        elementUri,
        typeArgs,
        registry,
      );
    }

    // C. Handle Direct Match
    // 1. Name Check
    if (def.type != null && def.type != elementName) return false;

    // 2. Import Check (if defined)
    if (def.import != null) {
      if (elementUri != null && elementUri != def.import) return false;
    }

    // 3. Generics Check (The hard part)
    // If the definition specifies arguments, the actual type MUST match them.
    if (def.arguments.isNotEmpty) {
      // If code has fewer args than config requires, fail.
      if (typeArgs.length < def.arguments.length) return false;

      for (var i = 0; i < def.arguments.length; i++) {
        final argDef = def.arguments[i];
        final actualArgType = typeArgs[i];

        final actualArgName = actualArgType.element?.name;
        final actualArgUri = actualArgType.element?.library?.firstFragment.source.uri.toString();
        final nestedArgs = _getTypeArguments(actualArgType);

        if (!_matchesDefinitionRecursive(
          argDef,
          actualArgName,
          actualArgUri,
          nestedArgs,
          registry,
        )) {
          return false;
        }
      }
    }

    return true;
  }

  /// Converts a constraint into a human-readable string.
  /// Looks up definition keys in [registry] to find the actual Class Name.
  String describeConstraint(TypeSafetyConstraint c, Map<String, TypeDefinition> registry) {
    // 1. Definitions (Lookup key -> type name)
    if (c.definitions.isNotEmpty) {
      return c.definitions
          .map((key) {
            // Return the actual type name (e.g. 'FutureEither') or fallback to key
            return registry[key]?.type ?? key;
          })
          .join(' or ');
    }

    // 2. Raw Types
    if (c.types.isNotEmpty) return c.types.join(' or ');

    // 3. Component
    if (c.component != null) return 'Component: ${c.component}';

    return 'Defined Rule';
  }
}
