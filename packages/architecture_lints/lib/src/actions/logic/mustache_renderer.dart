import 'package:mustache_template/mustache_template.dart';

class MustacheRenderer {
  const MustacheRenderer();

  /// Renders a template string with the given context.
  String render(String templateString, Map<String, dynamic> context) {
    try {
      // 'lenient: true' allows undefined variables to be empty strings instead of crashing
      final template = Template(templateString, lenient: true);
      return template.renderString(context);
    } catch (e) {
      return '/* Error rendering template: $e */';
    }
  }
}