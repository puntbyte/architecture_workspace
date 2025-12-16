import 'dart:io';
import 'package:architecture_lints/src/engines/template/template_loader.dart';
import 'package:architecture_lints/src/config/schema/template_definition.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('TemplateLoader', () {
    late Directory tempDir;
    late TemplateLoader loader;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('loader_test_');
      loader = TemplateLoader(tempDir.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('should return inline content directly', () {
      const def = TemplateDefinition(content: 'Inline Data');
      final result = loader.loadContent(def);
      expect(result, 'Inline Data');
    });

    test('should load content from file relative to root', () {
      final tplFile = File(p.join(tempDir.path, 'templates', 'test.mustache'))
        ..createSync(recursive: true)
        ..writeAsStringSync('File Data');

      final def = TemplateDefinition(filePath: 'templates/test.mustache');
      final result = loader.loadContent(def);

      expect(result, 'File Data');
    });

    test('should throw StateError if file does not exist', () {
      final def = const TemplateDefinition(filePath: 'missing.mustache');

      expect(
            () => loader.loadContent(def),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Template file not found'))),
      );
    });
  });
}