// lib/src/utils/nlp/naming_utils.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/configs/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';

class NamingStrategy {
  final List<_ComponentPattern> _sortedPatterns;

  NamingStrategy(List<NamingRule> rules) : _sortedPatterns = _createSortedPatterns(rules);

  /// Checks if the [className] found in [actualComponent] matches a
  /// DIFFERENT component pattern more specifically.
  ///
  /// [structuralComponent]: The component type derived from inheritance (optional).
  ///
  /// Returns `true` if the naming lint should yield (stop processing).
  bool shouldYieldToLocationLint(
    String className,
    ArchComponent actualComponent,
    ArchComponent? structuralComponent,
  ) {
    // 1. Structural Check (Inheritance Override)
    // If the class explicitly inherits from the component type it is located in,
    // then it is definitely in the right place. Any naming mismatch is a Naming Error,
    // NOT a Location Error. We should NOT yield.
    if (structuralComponent != null && structuralComponent == actualComponent) {
      return false;
    }

    // 2. Find the best matching component for this name based on all rules.
    final bestMatchComponent = _getBestGuessComponent(className);

    // If the name doesn't match ANY known pattern, we can't claim it belongs elsewhere.
    if (bestMatchComponent == null) return false;

    // If the name matches the component we are currently in, we don't yield.
    if (bestMatchComponent == actualComponent) return false;

    // 3. Collision/Ambiguity Check:
    if (_matchesComponentPattern(className, actualComponent)) {
      return false;
    }

    // 4. Yield:
    // Name matches another component better, and inheritance didn't confirm strict identity.
    return true;
  }

  ArchComponent? _getBestGuessComponent(String className) {
    final bestMatch = _sortedPatterns.firstWhereOrNull(
      (p) => NamingUtils.validateName(name: className, template: p.pattern),
    );
    return bestMatch?.component;
  }

  bool _matchesComponentPattern(String className, ArchComponent component) {
    final rules = _sortedPatterns.where((p) => p.component == component);
    return rules.any((p) => NamingUtils.validateName(name: className, template: p.pattern));
  }

  static List<_ComponentPattern> _createSortedPatterns(List<NamingRule> rules) {
    final patterns =
        rules
            .expand((rule) {
              return rule.on.map((componentId) {
                final component = ArchComponent.fromId(componentId);
                return component != ArchComponent.unknown
                    ? _ComponentPattern(pattern: rule.pattern, component: component)
                    : null;
              });
            })
            .whereNotNull()
            .toList()
          ..sort((a, b) => b.pattern.length.compareTo(a.pattern.length));

    return patterns;
  }
}

class _ComponentPattern {
  final String pattern;
  final ArchComponent component;

  const _ComponentPattern({required this.pattern, required this.component});
}
