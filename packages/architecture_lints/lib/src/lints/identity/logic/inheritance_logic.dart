import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/type_definition.dart';
import 'package:architecture_lints/src/config/schema/type_reference.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

mixin InheritanceLogic {
  bool matchesReference(
      InterfaceType type,
      TypeReference reference,
      FileResolver fileResolver,
      Map<String, TypeDefinition> typeRegistry,
      ) {
    final element = type.element;

    // 1. Check Class Name
    if (reference.types.contains(element.name)) {
      if (reference.import != null) {
        final libraryUri = element.library.firstFragment.source.uri.toString();
        return libraryUri == reference.import;
      }
      return true;
    }

    // 2. Check Component
    if (reference.component != null) {
      final sourcePath = element.library.firstFragment.source.fullName;
      final componentConfig = fileResolver.resolve(sourcePath);

      if (componentConfig != null) {
        if (componentConfig.id == reference.component ||
            componentConfig.id.startsWith('${reference.component}.')) {
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

  bool componentMatches(String ruleId, String componentId) {
    if (ruleId == componentId) return true;
    if (componentId.startsWith('$ruleId.')) return true;
    if (componentId.endsWith('.$ruleId')) return true;
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

  /// Returns a human-readable description of the rule.
  /// If [registry] is provided, it resolves definition keys to class names.
  String describeReference(TypeReference ref, [Map<String, TypeDefinition>? registry]) {
    // 1. Explicit Types
    if (ref.types.isNotEmpty) {
      return ref.types.join(' or ');
    }

    // 2. Component Reference
    if (ref.component != null) {
      return 'Component: ${ref.component}';
    }

    // 3. Definitions (The change is here)
    if (ref.definitions.isNotEmpty) {
      if (registry != null) {
        // Map keys (usecase.unary) to class names (UnaryUsecase)
        final names = ref.definitions.map((key) {
          return registry[key]?.type ?? key; // Fallback to key if missing
        }).toSet(); // Deduplicate just in case

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
      if (element.supertype != null && !element.supertype!.isDartCoreObject)
        element.supertype!,
      ...element.mixins,
      ...element.interfaces,
    ];
  }
}