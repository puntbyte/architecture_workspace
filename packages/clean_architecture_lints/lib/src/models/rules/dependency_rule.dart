part of 'package:clean_architecture_lints/src/models/dependencies_config.dart';

class DependencyRule {
  final List<String> on;
  final DependencyDetail allowed;
  final DependencyDetail forbidden;

  const DependencyRule({required this.on, required this.allowed, required this.forbidden});

  static DependencyRule? fromMap(Map<String, dynamic> map) {
    final on = map.asStringList(ConfigKey.dependency.on);
    if (on.isEmpty) return null;

    return DependencyRule(
      on: on,
      // Pass the raw value (Map or List) to the Detail parser
      allowed: DependencyDetail.fromMap(map[ConfigKey.dependency.allowed]),
      forbidden: DependencyDetail.fromMap(map[ConfigKey.dependency.forbidden]),
    );
  }
}
