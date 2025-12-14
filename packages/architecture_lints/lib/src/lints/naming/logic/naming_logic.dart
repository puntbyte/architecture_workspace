// lib/src/naming/logic/naming_logic.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';

mixin NamingLogic {
  static final Map<String, RegExp> _regexCache = {};

  bool validateName(String className, String pattern) {
    if (pattern == ConfigKeys.placeholder.name) {
      return RegExp('^${ConfigKeys.regex.pascalCaseGroup}\$').hasMatch(className);
    }
    final regex = _getRegex(pattern);
    return regex.hasMatch(className);
  }

  /// Extracts the value of {{name}} from a class name based on the pattern.
  /// Returns null if the class name doesn't match the pattern.
  String? extractCoreNameFromPattern(String className, String pattern) {
    final regex = _getRegex(pattern);
    final match = regex.firstMatch(className);
    if (match != null && match.groupCount >= 1) return match.group(1);
    return null;
  }

  RegExp _getRegex(String pattern) => _regexCache.putIfAbsent(pattern, () => _buildRegex(pattern));

  RegExp _buildRegex(String pattern) {
    // 1. Escape the pattern to treat literals (like dots/brackets) safely.
    //    We use the PathMatcher helper or RegExp.escape.
    var regexStr = PathMatcher.escapeRegex(pattern);

    // 2. Identify the escaped placeholders.
    //    Since we escaped the pattern, '${name}' became '\$\{name\}'.
    //    We must look for that escaped string to replace it.
    final escapedName = PathMatcher.escapeRegex(ConfigKeys.placeholder.name);
    final escapedAffix = PathMatcher.escapeRegex(ConfigKeys.placeholder.affix);

    // 3. Inject Regex Groups
    regexStr = regexStr
        .replaceAll(escapedName, ConfigKeys.regex.pascalCaseGroup)
        .replaceAll(escapedAffix, ConfigKeys.regex.wildcard);

    return RegExp('^$regexStr\$');
  }

  String generateExample(String pattern) {
    return pattern
        .replaceAll(ConfigKeys.placeholder.name, 'Login')
        .replaceAll(ConfigKeys.placeholder.affix, 'My')
        // Clean up regex artifacts for display if present
        .replaceAll(RegExp(r'[\(\)\|]'), '') // Remove ( ) |
        .replaceAll(r'\', '');
  }
}
