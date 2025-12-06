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
    // Optimization: Direct equality check for simple patterns
    if (pattern == _placeholderName) {
      return RegExp('^$_regexPascalCaseGroup\$').hasMatch(className);
    }

    final regex = _regexCache.putIfAbsent(pattern, () => _buildRegex(pattern));
    return regex.hasMatch(className);
  }

  RegExp _buildRegex(String pattern) {
    // FIX: Do NOT use RegExp.escape(pattern).
    // The configuration supports Regex syntax (like '(C|c)'), so we must preserve it.
    // We only replace the specific placeholders.

    final regexString = pattern
        .replaceAll(_placeholderName, _regexPascalCaseGroup)
        .replaceAll(_placeholderAffix, _regexWildcard);

    return RegExp('^$regexString\$');
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
