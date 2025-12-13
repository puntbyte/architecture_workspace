// lib/src/config/schema/template_loader.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class TemplateDefinition {
  final String? content;
  final String? filePath;
  final String? description;

  const TemplateDefinition({this.content, this.filePath, this.description});

  factory TemplateDefinition.fromDynamic(dynamic value) {
    if (value is String) return TemplateDefinition(content: value);
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return TemplateDefinition(
        filePath: map.tryGetString(ConfigKeys.template.file),
        content: map.tryGetString(ConfigKeys.template.content),
        description: map.tryGetString(ConfigKeys.template.description),
      );
    }
    return const TemplateDefinition();
  }
}
