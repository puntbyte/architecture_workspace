import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/module_resolver.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/domain/module_context.dart';

class FileResolver {
  final ArchitectureConfig config;
  final ModuleResolver _moduleResolver;

  FileResolver(this.config) : _moduleResolver = ModuleResolver(config.modules);

  /// Standard resolution (Path only). Used when AST is not available.
  /// Returns the "Best Path Match" candidate.
  ComponentContext? resolve(String filePath) {
    final candidates = resolveAllCandidates(filePath);
    if (candidates.isEmpty) return null;

    // Default sorting: Specificity (Depth > Length > ID)
    // sort descending (b compareTo a)
    candidates.sort((a, b) => b.compareTo(a));

    final best = candidates.first;
    final module = _moduleResolver.resolve(filePath);

    return ComponentContext(
      filePath: filePath,
      config: best.component,
      module: module,
    );
  }

  /// Returns ALL components that match the file path.
  List<Candidate> resolveAllCandidates(String filePath) {
    final normalizedFile = filePath.replaceAll(r'\', '/');
    final matches = <Candidate>[];

    for (final component in config.components) {
      if (component.paths.isEmpty) continue;

      for (final path in component.paths) {
        final matchIndex = PathMatcher.getMatchIndex(normalizedFile, path);

        if (matchIndex != -1) {
          matches.add(
            Candidate(
              component: component,
              matchLength: path.length,
              matchIndex: matchIndex,
            ),
          );

          // Optimization: Once a component matches a file path via one rule,
          // we don't need to check its other path aliases for the same file.
          break;
        }
      }
    }
    return matches;
  }

  ModuleContext? resolveModule(String filePath) => _moduleResolver.resolve(filePath);
}

/// A potential match for a file.
class Candidate implements Comparable<Candidate> {
  /// The component configuration.
  final ComponentConfig component;

  /// Length of the path segment matched (Longer = More Specific).
  final int matchLength;

  /// Start index of the match (Higher/Deeper = More Specific).
  /// e.g. 'domain/entities' (index 10) is better than 'domain' (index 0).
  final int matchIndex;

  Candidate({
    required this.component,
    required this.matchLength,
    required this.matchIndex,
  });

  @override
  int compareTo(Candidate other) {
    // 1. Specificity: Deeper matches win
    final indexCmp = matchIndex.compareTo(other.matchIndex);
    if (indexCmp != 0) return indexCmp;

    // 2. Length: Longer path definition wins
    final lenCmp = matchLength.compareTo(other.matchLength);
    if (lenCmp != 0) return lenCmp;

    // 3. ID Length: Tie-breaker for co-located components (Child > Parent)
    // e.g. 'data.source.implementation' > 'data.source'
    return component.id.length.compareTo(other.component.id.length);
  }

  @override
  String toString() => 'Candidate(${component.id}, score: $matchIndex/$matchLength)';
}
