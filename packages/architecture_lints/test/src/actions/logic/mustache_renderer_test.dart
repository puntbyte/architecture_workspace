import 'package:architecture_lints/src/engines/template/mustache_renderer.dart';
import 'package:test/test.dart';

void main() {
  group('MustacheRenderer', () {
    const renderer = MustacheRenderer();

    test('should render simple variable replacement', () {
      const template = 'Hello {{name}}!';
      final context = {'name': 'World'};

      expect(renderer.render(template, context), 'Hello World!');
    });

    test('should handle missing variables gracefully (lenient)', () {
      const template = 'Hello {{missing}}!';
      final context = {'name': 'World'};

      // Default mustache behavior for missing vars is empty string
      expect(renderer.render(template, context), 'Hello !');
    });

    test('should render sections', () {
      const template = '{{#flag}}Show{{/flag}}{{^flag}}Hide{{/flag}}';

      expect(renderer.render(template, {'flag': true}), 'Show');
      expect(renderer.render(template, {'flag': false}), 'Hide');
    });
  });
}