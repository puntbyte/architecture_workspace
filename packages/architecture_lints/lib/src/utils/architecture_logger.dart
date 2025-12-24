import 'dart:developer' as dev;

class ArchLogger {
  const ArchLogger._();

  static bool _enabled = false;
  static final Set<String> _allowedTags = {};
  static final Set<String> _mutedTags = {};

  /// Global switch to turn logging on/off.
  static void configure({bool enabled = true}) {
    _enabled = enabled;
  }

  /// Only show logs with these tags. If empty, all tags (except muted) are shown.
  static void includeTags(List<String> tags) {
    _allowedTags.clear();
    _allowedTags.addAll(tags);
  }

  /// Hide logs with these tags.
  static void muteTags(List<String> tags) {
    _mutedTags.addAll(tags);
  }

  static void reset() {
    _enabled = false;
    _allowedTags.clear();
    _mutedTags.clear();
  }

  /// Log a message.
  /// [tag]: The source of the log (e.g. 'GrammarLogic', 'FileResolver').
  static void log(String message, {String tag = 'General'}) {
    if (!_enabled) return;
    if (_mutedTags.contains(tag)) return;

    // Filter logic: If whitelist exists, must be in it.
    if (_allowedTags.isNotEmpty && !_allowedTags.contains(tag)) return;

    // Use dart:developer log for better IDE integration, or print for CLI
    // Note: 'print' ensures it shows up in 'dart test' output stdout.
    print('[$tag] $message');
  }
}