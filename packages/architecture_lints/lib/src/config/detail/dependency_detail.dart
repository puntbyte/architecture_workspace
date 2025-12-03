import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class DependencyDetail {
  final List<String> components;
  final List<String> imports;

  const DependencyDetail({
    this.components = const [],
    this.imports = const [],
  });

  /// Creates an empty detail (used when a rule is missing, e.g. no 'allowed' block).
  factory DependencyDetail.empty() => const DependencyDetail();

  /// Parsed from dynamic YAML value which could be:
  /// 1. String: 'domain' (Implies component)
  /// 2. List: ['domain', 'entity'] (Implies components)
  /// 3. Map: { component: [...], import: [...] } (Explicit)
  factory DependencyDetail.fromDynamic(dynamic value) {
    if (value == null) return DependencyDetail.empty();

    // Case 1: Shorthand List -> Components
    if (value is List) {
      return DependencyDetail(components: value.map((e) => e.toString()).toList());
    }

    // Case 2: Shorthand String -> Component
    if (value is String) return DependencyDetail(components: [value]);

    // Case 3: Explicit Map
    if (value is Map) {
      final map = Map<String, dynamic>.from(value); // Safe cast

      return DependencyDetail(
        components: map.getStringList(ConfigKeys.dependency.component),
        imports: map.getStringList(ConfigKeys.dependency.import),
      );
    }

    return DependencyDetail.empty();
  }

  bool get isEmpty => components.isEmpty && imports.isEmpty;

  bool get isNotEmpty => !isEmpty;
}
