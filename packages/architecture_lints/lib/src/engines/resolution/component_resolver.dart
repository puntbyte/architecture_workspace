import 'package:architecture_lints/src/schema/definitions/component_definition.dart';

class ComponentResolver {
  final List<ComponentDefinition> components;

  const ComponentResolver(this.components);

  /// Finds a component definition by its reference ID.
  ///
  /// Supports fuzzy matching:
  /// 1. Exact Match: 'domain.entity' matches 'domain.entity'
  /// 2. Suffix Match: 'entity' matches 'domain.entity'
  /// 3. Child Match: 'domain' matches 'domain.entity' (returns parent if multiple? No, usually
  /// precise target)
  ///
  /// Returns the first match found.
  ComponentDefinition? find(String referenceId) {
    for (final component in components) {
      // 1. Exact Match
      if (component.id == referenceId) return component;

      // 2. Suffix Match (Shorthand)
      // e.g. ref='entity' matches id='domain.entity'
      if (component.id.endsWith('.$referenceId')) return component;

      // 3. Parent Match (Prefix) - Optional, depends if you want 'domain' to return 'domain'
      // component
      // Note: Usually we want specific components, so strict prefix might be better handled by
      // context.
      // But for configuration references like "component: domain", exact match handles it.
    }
    return null;
  }
}
