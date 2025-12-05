import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart'; // Import Config
import 'package:architecture_lints/src/config/schema/type_definition.dart';
import 'package:architecture_lints/src/config/schema/type_reference.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

mixin InheritanceLogic {
  /// Attempts to identify the architectural component of a class based on what it extends/implements.
  /// Returns the [id] of the component if a match is found in the [inheritance] configuration.
  String? findComponentIdByInheritance(
    ClassDeclaration node,
    ArchitectureConfig config,
    FileResolver fileResolver,
  ) {
    // Access element via declaredFragment (Analyzer 8.x+)
    final element = node.declaredFragment?.element;
    if (element == null) return null;

    final supertypes = getImmediateSupertypes(element);
    if (supertypes.isEmpty) return null;

    // Iterate through all inheritance rules defined in config
    for (final rule in config.inheritances) {
      // We are looking for "Identification Rules" (Required inheritance).
      // If a rule says: "Components of type 'X' MUST extend 'Y'",
      // and our class extends 'Y', then our class is likely of type 'X'.
      if (rule.required.isEmpty) continue;

      final matchesRule = supertypes.any(
        (type) => matchesReference(
          type,
          rule.required,
          fileResolver,
          config.typeDefinitions,
        ),
      );

      if (matchesRule && rule.onIds.isNotEmpty) {
        // Return the first component ID this rule applies to.
        return rule.onIds.first;
      }
    }

    return null;
  }

  bool matchesReference(
    InterfaceType type,
    TypeReference reference,
    FileResolver fileResolver,
    Map<String, TypeDefinition> typeRegistry,
  ) {
    final element = type.element;

    // 1. Check Class Name & Import
    if (reference.types.contains(element.name)) {
      if (reference.import != null) {
        final libraryUri = element.library.firstFragment.source.uri.toString();
        return libraryUri == reference.import;
      }
      return true;
    }

    // 2. Check Component Reference
    if (reference.component != null) {
      final sourcePath = element.library.firstFragment.source.fullName;
      final componentContext = fileResolver.resolve(sourcePath);

      if (componentContext != null) {
        if (componentContext.matchesReference(reference.component!)) {
          return true;
        }
      }
    }

    // 3. Check Definitions
    if (reference.definitions.isNotEmpty) {
      for (final defId in reference.definitions) {
        final definition = typeRegistry[defId];
        if (definition == null) continue;

        if (definition.type == element.name) {
          if (definition.import != null) {
            final libraryUri = element.library.firstFragment.source.uri.toString();
            if (libraryUri != definition.import) continue;
          }
          return true;
        }
      }
    }

    return false;
  }

  AstNode? getNodeForType(ClassDeclaration node, InterfaceType type) {
    if (node.extendsClause?.superclass.type == type) {
      return node.extendsClause!.superclass;
    }
    if (node.implementsClause != null) {
      for (final interface in node.implementsClause!.interfaces) {
        if (interface.type == type) return interface;
      }
    }
    if (node.withClause != null) {
      for (final mixin in node.withClause!.mixinTypes) {
        if (mixin.type == type) return mixin;
      }
    }
    return null;
  }

  String describeReference(TypeReference ref, [Map<String, TypeDefinition>? registry]) {
    if (ref.types.isNotEmpty) return ref.types.join(' or ');
    if (ref.component != null) return 'Component: ${ref.component}';
    if (ref.definitions.isNotEmpty) {
      if (registry != null) {
        final names = ref.definitions.map((key) => registry[key]?.type ?? key).toSet();
        return names.join(' or ');
      }
      return 'Defined: ${ref.definitions.join(', ')}';
    }
    return 'Defined Rule';
  }

  void report({
    required DiagnosticReporter reporter,
    required Object nodeOrToken,
    required LintCode code,
    required List<Object> arguments,
  }) {
    if (nodeOrToken is AstNode) {
      reporter.atNode(nodeOrToken, code, arguments: arguments);
    } else if (nodeOrToken is Token) {
      reporter.atToken(nodeOrToken, code, arguments: arguments);
    }
  }

  List<InterfaceType> getImmediateSupertypes(InterfaceElement element) {
    return [
      if (element.supertype != null && !element.supertype!.isDartCoreObject) element.supertype!,
      ...element.mixins,
      ...element.interfaces,
    ];
  }
}
