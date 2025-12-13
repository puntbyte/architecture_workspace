// lib/src/naming/logic/naming_logic.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';

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

  RegExp _getRegex(String pattern) {
    return _regexCache.putIfAbsent(pattern, () => _buildRegex(pattern));
  }

  RegExp _buildRegex(String pattern) {
    var regexStr = pattern;

    // Replace ${name} -> ([A-Z]...)
    regexStr = regexStr.replaceAll(ConfigKeys.placeholder.name, ConfigKeys.regex.pascalCaseGroup);

    // Replace ${affix} -> .*
    regexStr = regexStr.replaceAll(ConfigKeys.placeholder.affix, ConfigKeys.regex.wildcard);

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
