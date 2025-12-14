import 'package:architecture_lints/src/config/constants/config_keys.dart';

class PathMatcher {
  /// Returns the start index of the match in [filePath], or -1 if no match.
  static int getMatchIndex(String filePath, String configPath) {
    final normalizedFile = filePath.replaceAll(r'\', '/');
    final normalizedConfig = configPath.replaceAll(r'\', '/');

    final namePlaceholder = ConfigKeys.placeholder.name;

    // 1. Handle {{name}} / ${name} wildcard
    if (normalizedConfig.contains(namePlaceholder)) {
      // Escape the config string to treat path separators/dots as literals
      final escapedConfig = escapeRegex(normalizedConfig);
      // Escape the placeholder to find it inside the escaped config
      final escapedPlaceholder = escapeRegex(namePlaceholder);

      // Replace placeholder with Regex group for "anything except slash"
      final pattern = escapedConfig.replaceAll(escapedPlaceholder, '[^/]+');

      final regex = RegExp(pattern);
      final match = regex.firstMatch(normalizedFile);
      return match?.start ?? -1;
    }

    // 2. Handle standard Glob wildcard (*)
    if (normalizedConfig.contains('*')) {
      final pattern = escapeRegex(normalizedConfig).replaceAll(r'\*', '.*');
      final regex = RegExp(pattern);
      final match = regex.firstMatch(normalizedFile);
      return match?.start ?? -1;
    }

    // 3. Robust Containment Check
    // We check for folder boundaries to avoid partial name matches (e.g. 'port' matching 'support')

    // Check '/configPath/' (Middle)
    final index = normalizedFile.indexOf('/$normalizedConfig/');
    if (index != -1) return index + 1; // +1 to skip the leading slash

    // Check '/configPath' (End)
    if (normalizedFile.endsWith('/$normalizedConfig')) {
      return normalizedFile.length - normalizedConfig.length;
    }

    // Check 'configPath/' (Start)
    if (normalizedFile.startsWith('$normalizedConfig/')) return 0;

    // Fallback: Exact match
    if (normalizedFile == normalizedConfig) return 0;

    return -1;
  }

  static bool matches(String filePath, String configPath) {
    // 1. Handle file extension check specifically for excludes like '*.g.dart'
    if (configPath.startsWith('*') && !configPath.contains('/')) {
      final extension = configPath.substring(1); // remove *
      return filePath.endsWith(extension);
    }

    // 2. Fallback to standard index matching
    return getMatchIndex(filePath, configPath) != -1;
  }

  static String escapeRegex(String text) {
    return text.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (match) => '\\${match.group(0)}');
  }
}
