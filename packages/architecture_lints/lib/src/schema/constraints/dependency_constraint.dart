import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class DependencyConstraint {
  final List<String> components;
  final List<String> imports;

  const DependencyConstraint({
    this.components = const [],
    this.imports = const [],
  });

  /// Creates an empty detail (used when a rule is missing, e.g. no 'allowed' block).
  factory DependencyConstraint.empty() => const DependencyConstraint();

  /// Parsed from dynamic YAML value which could be:
  /// 1. String: 'domain' (Implies component)
  /// 2. List: ['domain', 'entity'] (Implies components)
  /// 3. Map: { component: [...], import: [...] } (Explicit)
  factory DependencyConstraint.fromDynamic(dynamic value) {
    if (value == null) return DependencyConstraint.empty();

    // Case 1: Shorthand List -> Components
    if (value is List) return DependencyConstraint(components: value.map((e) => e.toString()).toList());


    // Case 2: Shorthand String -> Component
    if (value is String) return DependencyConstraint(components: [value]);

    // Case 3: Explicit Map
    if (value is Map) {
      final map = Map<String, dynamic>.from(value); // Safe cast

      return DependencyConstraint(
        components: map.getStringList(ConfigKeys.dependency.component),
        imports: map.getStringList(ConfigKeys.dependency.import),
      );
    }

    return DependencyConstraint.empty();
  }

  bool get isEmpty => components.isEmpty && imports.isEmpty;

  bool get isNotEmpty => !isEmpty;
}
