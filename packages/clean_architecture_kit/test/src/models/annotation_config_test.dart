// test/src/models/annotation_config_test.dart

import 'package:clean_architecture_kit/src/models/dependency_injection_config.dart';
import 'package:test/test.dart';

void main() {
  group('AnnotationConfig', () {
    group('fromMap factory', () {
      test('should create a valid config from a complete map', () {
        final map = {
          'import_path': 'package:injectable/injectable.dart',
          'annotation_text': '@Injectable()',
        };

        final config = AnnotationConfig.fromMap(map);

        expect(config.importPath, 'package:injectable/injectable.dart');
        expect(config.annotationText, '@Injectable()');
      });

      test('should handle missing keys gracefully, resulting in empty strings', () {
        final map = <String, dynamic>{};
        final config = AnnotationConfig.fromMap(map);

        expect(config.importPath, '');
        expect(config.annotationText, '');
      });

      test('should handle one missing key', () {
        final map = {'annotation_text': '@Singleton()'};
        final config = AnnotationConfig.fromMap(map);

        expect(config.importPath, '');
        expect(config.annotationText, '@Singleton()');
      });
    });
  });
}
