// lib/src/config/parsing/hierarchy_parser.dart

typedef _JsonMap = Map<String, dynamic>;
typedef _NodeFactory<T> = T Function(String id, dynamic value);
typedef _NodePredicate = bool Function(dynamic value);
typedef _NodeErrorHandler = void Function(Object error, StackTrace stack);

class HierarchyParser {
  const HierarchyParser._();

  /// Parse a YAML-like hierarchical structure into a map of id -> T using [factory].
  ///
  /// [inheritProperties]: Properties that flow from Parent -> Child.
  /// [cascadeProperties]: Properties that flow from Sibling -> Sibling.
  /// [scopeKeys]: If provided, only top-level keys matching this set are parsed.
  static Map<String, T> parse<T>({
    required Map<String, dynamic> yaml,
    required T Function(String id, dynamic value) factory,
    Set<String> scopeKeys = const {},
    List<String> inheritProperties = const [],
    List<String> cascadeProperties = const [],
    String? shorthandKey,
    bool Function(dynamic value)? shouldParseNode,
    void Function(Object error, StackTrace stack)? onError,
  }) {
    final results = <String, T>{};

    // Optimization: Use Sets for O(1) lookup
    final inheritSet = Set<String>.unmodifiable(inheritProperties);
    final cascadeSet = Set<String>.unmodifiable(cascadeProperties);
    final scopeSet = Set<String>.unmodifiable(scopeKeys);

    _parseNode<T>(
      node: yaml,
      parentId: '',
      results: results,
      scopeKeys: scopeSet,
      inheritProperties: inheritSet,
      cascadeProperties: cascadeSet,
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
    required String? shorthandKey,
    required _JsonMap contextData,
    required _NodeFactory<T> factory,
    _NodePredicate? shouldParseNode,
    _NodeErrorHandler? onError,
  }) {
    // 1) Normalize Node: Expand shorthand string to Map if needed
    final mapNode = _toMapNode(node, shorthandKey);

    // 2) Context: Merge parent context into current node
    final dataForChildren = _mergeContextToNode(mapNode, contextData, inheritProperties);

    // Use original node if map conversion returned null (e.g. List or primitive without shorthand)
    final dynamic effectiveNode = mapNode ?? node;

    // 3) Create Object: Call factory (skip root container where parentId == '')
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

    // 4) Recursion: If node isn't a Map, we can't iterate children.
    if (node is! Map) return;

    // 5) Children: Iterate with sibling context support
    final siblingContext = <String, dynamic>{};

    for (final entry in node.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      final nextParentId = _computeNextParentId(key, parentId, scopeKeys);

      // If null, it means this key is metadata or out of scope.
      if (nextParentId == null) continue;

      // Determine if we should reset context (start of a new root branch)
      final resetContext = _shouldResetContext(parentId, key);

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
        shorthandKey: shorthandKey,
        contextData: childContext,
        factory: factory,
        shouldParseNode: shouldParseNode,
        onError: onError,
      );

      // Sibling Cascade: Update context for *next* iteration
      if (value is Map) {
        for (final prop in cascadeProperties) {
          if (value.containsKey(prop)) siblingContext[prop] = value[prop];
        }
      }
    }
  }

  // --- Helpers ---

  static _JsonMap? _toMapNode(dynamic node, String? shorthandKey) {
    if (node is Map) {
      return Map<String, dynamic>.from(node);
    } else if (shorthandKey != null && node is String) {
      return <String, dynamic>{shorthandKey: node};
    }

    return null;
  }

  static _JsonMap _mergeContextToNode(
    _JsonMap? mapNode,
    _JsonMap contextData,
    Set<String> inheritProps,
  ) {
    // If context is empty, no merge needed.
    if (contextData.isEmpty) return mapNode ?? {};

    // If no node map, just pass context down (intermediate structure)
    if (mapNode == null) return Map.from(contextData);

    // Apply Parent Context to current Node (only if key missing in Node)
    for (final entry in contextData.entries) {
      mapNode.putIfAbsent(entry.key, () => entry.value);
    }

    // Calculate context for next generation
    final nextContext = Map<String, dynamic>.from(contextData);

    // Override with current node's values ONLY for inherited properties
    for (final prop in inheritProps) {
      if (mapNode.containsKey(prop)) nextContext[prop] = mapNode[prop];
    }

    return nextContext;
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

    // Optimization: if no sibling context, just return base
    if (siblingContext.isEmpty) return baseContext;

    final context = Map<String, dynamic>.from(baseContext)..addAll(siblingContext);
    return context;
  }

  static String? _computeNextParentId(
    String key,
    String parentId,
    Set<String> scopeKeys,
  ) {
    // 1. Child Node (starts with dot)
    if (key.startsWith('.')) {
      final suffix = key.substring(1);
      return parentId.isEmpty ? suffix : '$parentId.$suffix';
    }

    // 2. Root Scope
    // If we are at the top level (parentId is empty)
    if (parentId.isEmpty) {
      // If scopeKeys is empty, accept everything.
      // If scopeKeys is not empty, only accept matching keys.
      if (scopeKeys.isEmpty || scopeKeys.contains(key)) return key;
    }

    return null;
  }

  static bool _shouldResetContext(String parentId, String key) {
    // If key starts with dot, it's a child -> Inherit
    if (key.startsWith('.')) return false;
    // If it's a root key, it implies a fresh start -> Reset
    if (parentId.isEmpty) return true;
    return false;
  }
}
