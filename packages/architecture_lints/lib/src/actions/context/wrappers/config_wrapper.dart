import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/config/schema/annotation_config.dart';
import 'package:architecture_lints/src/config/schema/annotation_constraint.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:collection/collection.dart';

/// Wraps [ArchitectureConfig] to provide helper methods for the Action Engine.
class ConfigWrapper {
  final ArchitectureConfig _config;

  const ConfigWrapper(this._config);

  /// Expose definitions map directly.
  Map<String, Definition> get definitions => _config.definitions;

  /// Semantic helper: config.definitionFor('usecase.unary')
  Definition? definitionFor(String key) {
    return _config.definitions[key];
  }

  /// Helper to find naming configuration for a specific component ID.
  /// Usage: config.namesFor('domain.port').pattern
  ///
  /// Returns a Map containing ListWrappers for patterns, antipatterns, etc.
  Map<String, dynamic>? namesFor(String componentId) {
    final component = _config.components.firstWhereOrNull((c) => c.id == componentId);

    if (component == null) return null;

    // Helper to wrap String lists
    ListWrapper<StringWrapper> wrap(List<String> list) {
      return ListWrapper(list.map(StringWrapper.new).toList());
    }

    return {
      // Map 'patterns' (plural in class) to 'pattern' (singular concept in usage)
      'pattern': wrap(component.patterns),
      'antipattern': wrap(component.antipatterns),
      'grammar': wrap(component.grammar),
      'path': wrap(component.paths),
    };
  }

  /// Helper to find required annotations for a specific component ID.
  Map<String, dynamic> annotationsFor(String componentId) {
    final rule = _config.annotations.firstWhereOrNull((r) {
      if (r.onIds.contains(componentId)) return true;
      if (r.onIds.any((id) => componentId.endsWith('.$id') || componentId == id)) return true;
      return false;
    });

    if (rule == null) {
      return {
        'required': <Definition>[],
        'forbidden': <Definition>[],
        'allowed': <Definition>[],
      };
    }

    List<Definition> mapConstraints(List<AnnotationConstraint> constraints) {
      final defs = <Definition>[];
      for (final c in constraints) {
        for (final type in c.types) {
          defs.add(Definition(
            types: [type],
            imports: c.import != null ? [c.import!] : [],
          ));
        }
      }
      return defs;
    }

    return {
      'required': mapConstraints(rule.required),
      'forbidden': mapConstraints(rule.forbidden),
      'allowed': mapConstraints(rule.allowed),
    };
  }
}