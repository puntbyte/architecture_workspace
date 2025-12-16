// lib/src/domain/component_context.dart

import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/context/module_context.dart';
import 'package:meta/meta.dart';

@immutable
class ComponentContext {
  final String filePath;
  final ComponentDefinition config;
  final ModuleContext? module;
  final String? debugScoreLog;

  const ComponentContext({
    required this.filePath,
    required this.config,
    this.module,
    this.debugScoreLog,
  });

  String get id => config.id;

  String get displayName => config.displayName;

  List<String> get patterns => config.patterns;

  List<String> get antipatterns => config.antipatterns;

  List<String> get grammar => config.grammar;

  bool matchesReference(String referenceId) {
    if (module != null && module!.key == referenceId) return true;
    if (id == referenceId) return true;

    final idSegments = id.split('.');
    final refSegments = referenceId.split('.');

    if (refSegments.length > idSegments.length) return false;

    for (var i = 0; i <= idSegments.length - refSegments.length; i++) {
      var match = true;
      for (var j = 0; j < refSegments.length; j++) {
        if (idSegments[i + j] != refSegments[j]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }

  bool matchesAny(List<String> referenceIds) => referenceIds.any(matchesReference);

  @override
  String toString() => 'ComponentContext(id: $id, module: ${module?.name})';
}
