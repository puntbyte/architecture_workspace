// lib/src/utils/naming_utils.dart
import 'package:architecture_lints/src/schema/constants/config_keys.dart';

class NamingUtils2 {
  const NamingUtils2._();

  // Regex: Capitalized letter followed by alphanumerics
  static const String _regexPascalCaseGroup = '([A-Z][a-zA-Z0-9]*)';

  // Regex: Any character sequence (non-greedy preferred usually, but greedy ok for now)
  static const String _regexWildcard = '.*';

  static final Map<String, RegExp> _expressionCache = {};

  static bool validateName({required String name, required String template}) {
    // If the template is exactly '{{name}}', it just means "Any PascalCase string"
    if (template == ConfigKeys.placeholder.name) {
      return RegExp('^$_regexPascalCaseGroup\$').hasMatch(name);
    }

    final regex = _expressionCache.putIfAbsent(template, () => _buildRegexForTemplate(template));
    return regex.hasMatch(name);
  }

  static RegExp _buildRegexForTemplate(String template) {
    var pattern = RegExp.escape(template); // ESCAPE FIRST to handle special chars in standard text

    // Un-escape the specific placeholders we support
    pattern = pattern
        .replaceAll(RegExp.escape(ConfigKeys.placeholder.name), _regexPascalCaseGroup)
        .replaceAll(RegExp.escape(ConfigKeys.placeholder.affix), _regexWildcard);

    // Anchor strictly to start (^) and end ($)
    return RegExp('^$pattern\$');
  }
}
