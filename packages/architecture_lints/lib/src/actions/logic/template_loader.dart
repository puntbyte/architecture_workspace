import 'dart:io';
import 'package:architecture_lints/src/config/schema/template_definition.dart';
import 'package:path/path.dart' as p;

class TemplateLoader {
  /// The root directory where architecture.yaml is located.
  final String configRoot;

  TemplateLoader(this.configRoot);

  /// Resolves the actual string content of a template.
  Future<String> loadContent(TemplateDefinition def) async {
    // 1. Inline Content (Fastest)
    if (def.content != null) {
      return def.content!;
    }

    // 2. File Reference
    if (def.filePath != null) {
      // Construct absolute path relative to config root
      final absolutePath = p.normalize(p.join(configRoot, def.filePath!));
      final file = File(absolutePath);

      if (!file.existsSync()) {
        // Fallback: Return empty or throw?
        // Throwing helps the user debug config errors.
        throw StateError('Template file not found: $absolutePath');
      }

      return await file.readAsString();
    }

    return ''; // Empty template fallback
  }
}