import 'package:architecture_lints/src/configuration/config_keys.dart';
import 'package:path/path.dart' as p;

class ComponentConfig {
  final String id;
  final String name;
  final String? path;
  final String? pattern;
  final String? antipattern;
  final String? grammar;

  const ComponentConfig({
    required this.id,
    required this.name,
    this.path,
    this.pattern,
    this.antipattern,
    this.grammar,
  });

  bool matchesPath(String relativeFilePath) {
    if (path == null) return false;
    final normalizedConfigPath = p.normalize(path!);
    final normalizedFilePath = p.normalize(relativeFilePath);

    // Simple containment check. 
    // e.g. "C:/.../lib/domain/entity/user.dart" contains "domain/entity"
    return normalizedFilePath.contains(normalizedConfigPath);
  }

  RegExp? get namingRegex {
    if (pattern == null) return null;

    final rawParams = pattern!
        .replaceAll(ConfigKeys.placeholder.name, '[A-Z][a-zA-Z0-9]*')
        .replaceAll(ConfigKeys.placeholder.affix, '.*');

    return RegExp('^$rawParams\$');
  }
}
