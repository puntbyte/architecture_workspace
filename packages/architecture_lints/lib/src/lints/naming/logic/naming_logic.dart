// lib/src/naming/logic/naming_logic.dart

mixin NamingLogic {
  static const String _placeholderName = '{{name}}';
  static const String _placeholderAffix = '{{affix}}';

  // PascalCase: Starts with Uppercase, followed by alphanumerics
  static const String _regexPascalCaseGroup = '([A-Z][a-zA-Z0-9]*)';

  // Wildcard: Matches anything
  static const String _regexWildcard = '.*';

  /// Static cache to avoid recompiling regexes for the same pattern strings.
  static final Map<String, RegExp> _regexCache = {};

  bool validateName(String className, String pattern) {
    if (pattern == _placeholderName) {
      return RegExp('^$_regexPascalCaseGroup\$').hasMatch(className);
    }
    final regex = _getRegex(pattern);
    return regex.hasMatch(className);
  }

  /// Extracts the value of {{name}} from a class name based on the pattern.
  /// Returns null if the class name doesn't match the pattern.
  String? extractCoreNameFromPattern(String className, String pattern) {
    final regex = _getRegex(pattern);
    final match = regex.firstMatch(className);

    if (match != null && match.groupCount >= 1) {
      // Since {{name}} is the only capturing group we explicitly define with (),
      // match.group(1) is the core name.
      // {{affix}} becomes .* which is non-capturing in standard regex unless wrapped.
      return match.group(1);
    }
    return null;
  }

  RegExp _getRegex(String pattern) {
    return _regexCache.putIfAbsent(pattern, () => _buildRegex(pattern));
  }

  RegExp _buildRegex(String pattern) {
    // 1. Escape the pattern to treat literals (like 'Use') as literals
    // Note: We don't use RegExp.escape() on the whole string because the user
    // might use regex syntax (e.g. (Bloc|Cubit)).
    // Ideally, we assume pattern is trusted or we manually handle placeholders.

    // For this implementation, we assume simple replacement:
    var regexStr = pattern;

    // Replace {{name}} with Capturing Group
    regexStr = regexStr.replaceAll(_placeholderName, _regexPascalCaseGroup);

    // Replace {{affix}} with Non-Capturing Wildcard
    regexStr = regexStr.replaceAll(_placeholderAffix, _regexWildcard);

    return RegExp('^$regexStr\$');
  }

  String generateExample(String pattern) {
    return pattern
        .replaceAll('{{name}}', 'Login')
        .replaceAll('{{affix}}', 'My')
        // Clean up regex artifacts for display if present
        .replaceAll(RegExp(r'[\(\)\|]'), '') // Remove ( ) |
        .replaceAll(r'\', '');
  }
}
