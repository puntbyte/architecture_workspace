import 'dart:io';
import 'package:architecture_lints/src/config/schema/template_definition.dart';
import 'package:path/path.dart' as p;

class TemplateLoader {
  final String configRoot;

  const TemplateLoader(this.configRoot);

  /// Resolves the actual string content of a template synchronously.
  String loadContent(TemplateDefinition def) {
    // 1. Inline Content
    if (def.content != null) return def.content!;

    // 2. File Reference
    if (def.filePath != null) {
      final absolutePath = p.normalize(p.join(configRoot, def.filePath!));
      final file = File(absolutePath);

      // We throw here so the generator can catch and log/ignore
      if (!file.existsSync()) throw StateError('Template file not found: $absolutePath');

      // SYNC READ
      return file.readAsStringSync();
    }

    return '';
  }
}
