// lib/src/config/schema/action_config.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ActionConfig {
  final String id;
  final String description;
  final ActionTrigger trigger;
  final ActionTarget target;
  final Map<String, VariableConfig> variables;
  final String templateId;
  final bool debug;

  const ActionConfig({
    required this.id,
    required this.description,
    required this.trigger,
    required this.target,
    required this.variables,
    required this.templateId,
    this.debug = false,
  });

  factory ActionConfig.fromMap(String id, Map<dynamic, dynamic> map) {
    return ActionConfig(
      id: id,
      description: map.getString('description', fallback: 'Fix issue'),
      trigger: ActionTrigger.fromMap(map.getMap('trigger')),
      target: ActionTarget.fromMap(map.getMap('target')),
      variables: _parseVariables(map['variables']),
      // Keep raw for Hierarchy parsing later
      templateId: map.mustGetString('template_id'),
      debug: map.getBool('debug', fallback: false),
    );
  }

  static List<ActionConfig> parseMap(Map<String, dynamic> map) {
    return map.entries.map((e) => ActionConfig.fromMap(e.key, e.value as Map)).toList();
  }

  static Map<String, VariableConfig> _parseVariables(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, VariableConfig>{};

    raw.forEach((key, value) {
      // In the root variables block, keys SHOULD start with '.'
      // per your hierarchy rules, or we can be lenient at the root.
      // Assuming strict consistency:
      final cleanKey = key.toString().startsWith('.')
          ? key.toString().substring(1)
          : key.toString();
      result[cleanKey] = VariableConfig.fromDynamic(value);
    });

    return result;
  }
}

@immutable
class ActionTrigger {
  final String? component;
  final String? element; // 'class', 'method'
  final String? errorCode; // 'arch_type_missing_base'

  const ActionTrigger({this.component, this.element, this.errorCode});

  factory ActionTrigger.fromMap(Map<String, dynamic> map) {
    return ActionTrigger(
      component: map.tryGetString('component'),
      element: map.tryGetString('element'),
      errorCode: map.tryGetString('error_code'),
    );
  }
}

@immutable
class ActionTarget {
  final String directory;
  final String filename;

  const ActionTarget({required this.directory, required this.filename});

  factory ActionTarget.fromMap(Map<String, dynamic> map) {
    return ActionTarget(
      directory: map.getString('directory', fallback: '.'),
      filename: map.mustGetString('filename'),
    );
  }
}
