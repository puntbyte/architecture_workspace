import 'package:path/path.dart' as p;

typedef _JsonMap = Map<String, dynamic>;
typedef _NodeFactory<T> = T Function(String id, dynamic value);
typedef _NodePredicate = bool Function(dynamic value);
typedef _NodeErrorHandler = void Function(Object error, StackTrace stack);

class HierarchyParser {
  const HierarchyParser._();

  static Map<String, T> parse<T>({
    required Map<String, dynamic> yaml,
    required T Function(String id, dynamic value) factory,
    Set<String> scopeKeys = const {},
    List<String> inheritProperties = const [],
    List<String> cascadeProperties = const [],
    List<String> pathProperties = const [],
    String? shorthandKey,
    bool Function(dynamic value)? shouldParseNode,
    void Function(Object error, StackTrace stack)? onError,
  }) {
    final results = <String, T>{};

    _parseNode<T>(
      node: yaml,
      parentId: '',
      results: results,
      scopeKeys: Set.unmodifiable(scopeKeys),
      inheritProperties: Set.unmodifiable(inheritProperties),
      cascadeProperties: Set.unmodifiable(cascadeProperties),
      pathProperties: Set.unmodifiable(pathProperties),
      shorthandKey: shorthandKey,
      contextData: const {},
      factory: factory,
      shouldParseNode: shouldParseNode,
      onError: onError,
    );

    return Map.unmodifiable(results);
  }

  static void _parseNode<T>({
    required dynamic node,
    required String parentId,
    required Map<String, T> results,
    required Set<String> scopeKeys,
    required Set<String> inheritProperties,
    required Set<String> cascadeProperties,
    required Set<String> pathProperties,
    required String? shorthandKey,
    required _JsonMap contextData,
    required _NodeFactory<T> factory,
    _NodePredicate? shouldParseNode,
    _NodeErrorHandler? onError,
  }) {
    // 1. Normalize Node
    final mapNode = _toMapNode(node, shorthandKey);

    // 2. Merge Context into Current Node
    // CRITICAL FIX: We must produce a 'mergedNode' that contains both the
    // context data (inherited props) and the local data.
    final mergedNode = _mergeContextAndNode(mapNode, contextData, pathProperties);

    // 3. Create Object using Merged Data
    // Use mergedNode if available, otherwise original node (for primitives that weren't maps)
    // Note: If node was primitive and contextData is NOT empty, we effectively ignore context
    // unless shorthand expansion happened. This is usually expected behavior.
    final dynamic effectiveNode = (mapNode != null) ? mergedNode : node;

    if (parentId.isNotEmpty) {
      _tryFactoryCreate(
        results: results,
        id: parentId,
        effectiveNode: effectiveNode,
        factory: factory,
        shouldParseNode: shouldParseNode,
        onError: onError,
      );
    }

    if (node is! Map) return;

    // 4. Prepare Context for Children
    // Only pass down properties marked for inheritance/pathing
    final dataForChildren = _filterContextForChildren(
      mergedNode,
      inheritProperties,
      pathProperties,
    );

    final siblingContext = <String, dynamic>{};

    for (final entry in node.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      final nextParentId = _computeNextParentId(key, parentId, scopeKeys);
      if (nextParentId == null) continue;

      final resetContext = _shouldResetContext(parentId, key);

      // Combine Parent Context + Sibling Context
      final childContext = _buildChildContext(
        resetContext: resetContext,
        baseContext: dataForChildren,
        siblingContext: siblingContext,
      );

      _parseNode<T>(
        node: value,
        parentId: nextParentId,
        results: results,
        scopeKeys: scopeKeys,
        inheritProperties: inheritProperties,
        cascadeProperties: cascadeProperties,
        pathProperties: pathProperties,
        shorthandKey: shorthandKey,
        contextData: childContext,
        factory: factory,
        shouldParseNode: shouldParseNode,
        onError: onError,
      );

      // Update Sibling Context for next iteration
      if (value is Map) {
        for (final prop in cascadeProperties) {
          if (value.containsKey(prop)) {
            siblingContext[prop] = value[prop];
          }
        }
      }
    }
  }

  static _JsonMap? _toMapNode(dynamic node, String? shorthandKey) {
    if (node is Map) return Map<String, dynamic>.from(node);
    if (shorthandKey != null && node is String) return {shorthandKey: node};
    return null;
  }

  /// Merges [contextData] into [mapNode], applying path joining where necessary.
  static _JsonMap _mergeContextAndNode(
    _JsonMap? mapNode,
    _JsonMap contextData,
    Set<String> pathProps,
  ) {
    if (contextData.isEmpty && mapNode == null) return {};
    if (contextData.isEmpty) return mapNode!;
    if (mapNode == null) return Map.from(contextData);

    final merged = Map<String, dynamic>.from(contextData);

    mapNode.forEach((key, childValue) {
      if (pathProps.contains(key) && merged.containsKey(key)) {
        // Join paths
        merged[key] = _joinPaths(merged[key], childValue);
      } else {
        // Override
        merged[key] = childValue;
      }
    });

    return merged;
  }

  /// Filters [mergedNode] to only include properties that should be inherited by children.
  static _JsonMap _filterContextForChildren(
    _JsonMap mergedNode,
    Set<String> inheritProps,
    Set<String> pathProps,
  ) {
    final nextContext = <String, dynamic>{};
    for (final key in mergedNode.keys) {
      if (inheritProps.contains(key) || pathProps.contains(key)) {
        nextContext[key] = mergedNode[key];
      }
    }
    return nextContext;
  }

  static dynamic _joinPaths(dynamic parent, dynamic child) {
    List<String> toList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String) return [v];
      return [];
    }

    final parents = toList(parent);
    final children = toList(child);

    if (parents.isEmpty) return child;
    if (children.isEmpty) return parent;

    final combined = <String>[];
    for (final pItem in parents) {
      for (final cItem in children) {
        combined.add(p.join(pItem, cItem));
      }
    }
    return combined.length == 1 ? combined.first : combined;
  }

  static void _tryFactoryCreate<T>({
    required Map<String, T> results,
    required String id,
    required dynamic effectiveNode,
    required _NodeFactory<T> factory,
    _NodePredicate? shouldParseNode,
    _NodeErrorHandler? onError,
  }) {
    final allowed = shouldParseNode == null || shouldParseNode(effectiveNode);
    if (!allowed) return;

    try {
      results[id] = factory(id, effectiveNode);
    } on Exception catch (error, stackTrace) {
      if (onError != null) onError(error, stackTrace);
    }
  }

  static _JsonMap _buildChildContext({
    required bool resetContext,
    required _JsonMap baseContext,
    required _JsonMap siblingContext,
  }) {
    if (resetContext) return <String, dynamic>{};
    if (siblingContext.isEmpty) return baseContext;
    final context = Map<String, dynamic>.from(baseContext);
    context.addAll(siblingContext);
    return context;
  }

  static String? _computeNextParentId(String key, String parentId, Set<String> scopeKeys) {
    if (key.startsWith('.')) {
      final suffix = key.substring(1);
      return parentId.isEmpty ? suffix : '$parentId.$suffix';
    }
    if (parentId.isEmpty) {
      if (scopeKeys.isEmpty || scopeKeys.contains(key)) return key;
    }
    return null;
  }

  static bool _shouldResetContext(String parentId, String key) {
    if (key.startsWith('.')) return false;
    if (parentId.isEmpty) return true;
    return false;
  }
}
