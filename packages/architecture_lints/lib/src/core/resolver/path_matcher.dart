// lib/src/core/resolver/path_matcher.dart

class PathMatcher {
  /// Checks if [filePath] matches the [configPath].
  ///
  /// [configPath] can be a simple string (e.g., 'domain/usecases')
  /// or contain wildcards (e.g., 'features/{{name}}/data').
  static bool matches(String filePath, String configPath) {
    // 1. Normalize separators to forward slashes for consistency
    final normalizedFile = filePath.replaceAll(r'\', '/');
    final normalizedConfig = configPath.replaceAll(r'\', '/');

    // 2. Handle {{name}} wildcard
    // Matches "features/{{name}}/data" against "features/auth/data"
    if (normalizedConfig.contains('{{name}}')) {
      // Escape special regex characters in the config path, except {{name}}
      final pattern = _escapeRegex(normalizedConfig)
          .replaceAll(r'\{\{name\}\}', '[^/]+'); // {{name}} becomes "anything except slash"

      final regex = RegExp(pattern);
      return regex.hasMatch(normalizedFile);
    }

    // 3. Handle standard Glob wildcard (*)
    if (normalizedConfig.contains('*')) {
      final pattern = _escapeRegex(normalizedConfig)
          .replaceAll(r'\*', '.*'); // * becomes "anything"

      final regex = RegExp(pattern);
      return regex.hasMatch(normalizedFile);
    }

    // 4. Robust Containment Check
    // We want to match 'domain' against 'lib/domain/file.dart'
    // But NOT against 'lib/domain_stuff/file.dart'

    // Check if normalizedFile contains the config path surrounded by separators
    // OR if it ends with the config path (folder name match)
    // OR if it contains config path followed by a slash.

    if (normalizedFile.contains('/$normalizedConfig/') ||
        normalizedFile.endsWith('/$normalizedConfig') ||
        normalizedFile.startsWith('$normalizedConfig/')) {
      return true;
    }

    // Fallback for simple relative matches if above is too strict for your use case
    // But generally, strictly checking boundaries prevents false positives.
    return false;
  }

  static String _escapeRegex(String text) {
    return text.replaceAllMapped(
        RegExp(r'[.*+?^${}()|[\]\\]'),
            (match) => '\\${match.group(0)}'
    );
  }
}
