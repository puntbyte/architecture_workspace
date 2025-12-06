// lib/src/config/parsing/hierarchy_parser.dart

class HierarchyParser {
  const HierarchyParser._();

  static Map<String, T> parse<T>({
    required Map<String, dynamic> yaml,
    required T Function(String id, dynamic value) factory,
    Set<String> scopeKeys = const {},
    List<String> inheritProperties = const [],
    List<String> cascadeProperties = const [],
    String? shorthandKey, // New: Key to use when expanding primitives
    bool Function(dynamic value)? shouldParseNode,
  }) {
    final results = <String, T>{};

    _parseNode(
      node: yaml,
      parentId: '',
      results: results,
      scopeKeys: scopeKeys,
      inheritProperties: inheritProperties,
      cascadeProperties: cascadeProperties,
      shorthandKey: shorthandKey,
      contextData: {},
      factory: factory,
      shouldParseNode: shouldParseNode,
    );

    return results;
  }

  static void _parseNode<T>({
    required dynamic node,
    required String parentId,
    required Map<String, T> results,
    required Set<String> scopeKeys,
    required List<String> inheritProperties,
    required List<String> cascadeProperties,
    required String? shorthandKey,
    required Map<String, dynamic> contextData,
    required T Function(String id, dynamic value) factory,
    bool Function(dynamic value)? shouldParseNode,
  }) {
    // 1. Prepare Effective Node Data
    dynamic effectiveNode = node;
    var dataForChildren = Map<String, dynamic>.from(contextData);

    // Expand Shorthand if applicable (String -> Map)
    Map<String, dynamic>? mapNode;
    if (node is Map) {
      mapNode = Map<String, dynamic>.from(node);
    } else if (shorthandKey != null && node is String) {
      mapNode = {shorthandKey: node};
    }

    // Apply Context (Inheritance/Cascading)
    if (mapNode != null) {
      for (final entry in contextData.entries) {
        if (!mapNode.containsKey(entry.key)) {
          mapNode[entry.key] = entry.value;
        }
      }

      effectiveNode = mapNode;

      // Update context for children (Parent Inheritance)
      for (final prop in inheritProperties) {
        if (mapNode.containsKey(prop)) {
          dataForChildren[prop] = mapNode[prop];
        }
      }
    } else {
      // Primitive node without expansion: just pass existing context down
      dataForChildren = contextData;
    }

    // 2. Parse Object
    if (parentId.isNotEmpty) {
      var isValid = true;
      if (shouldParseNode != null) {
        isValid = shouldParseNode(effectiveNode);
      }

      if (isValid) {
        try {
          results[parentId] = factory(parentId, effectiveNode);
        } catch (_) {}
      }
    }

    // 3. Iterate Children (Only if original node was a Map)
    if (node is! Map) return;

    final siblingContext = <String, dynamic>{};

    for (final entry in node.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      String? nextParentId;
      var resetContext = false;

      // Case A: Child
      if (key.startsWith('.')) {
        final suffix = key.substring(1);
        nextParentId = parentId.isEmpty ? suffix : '$parentId.$suffix';
      }
      // Case B: Root Scope
      else if (parentId.isEmpty && scopeKeys.contains(key)) {
        nextParentId = key;
        resetContext = true;
      }
      // Case C: Root Flat
      else if (parentId.isEmpty) {
        nextParentId = key;
        resetContext = true;
      }

      if (nextParentId != null) {
        final childContext = resetContext
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(dataForChildren);

        if (!resetContext) {
          siblingContext.forEach((k, v) => childContext[k] = v);
        }

        _parseNode(
          node: value,
          parentId: nextParentId,
          results: results,
          scopeKeys: scopeKeys,
          inheritProperties: inheritProperties,
          cascadeProperties: cascadeProperties,
          shorthandKey: shorthandKey,
          contextData: childContext,
          factory: factory,
          shouldParseNode: shouldParseNode,
        );

        // Update Sibling Context
        if (value is Map) {
          for (final prop in cascadeProperties) {
            if (value.containsKey(prop)) {
              siblingContext[prop] = value[prop];
            }
          }
        }
      }
    }
  }
}
