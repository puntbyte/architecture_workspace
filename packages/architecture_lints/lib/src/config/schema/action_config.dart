// lib/src/config/schema/action_config.dart

import 'package:architecture_lints/src/config/enums/action_scope.dart';
import 'package:architecture_lints/src/config/enums/write_placement.dart';
import 'package:architecture_lints/src/config/enums/write_strategy.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
@immutable
class ActionConfig {
  final String id;
  final String description;
  final ActionTrigger trigger;
  final ActionSource source;
  final ActionTarget target;
  final ActionWrite write;
  final Map<String, VariableConfig> variables;
  final String templateId;
  final bool debug;

  const ActionConfig({
    required this.id,
    required this.description,
    required this.trigger,
    required this.source,
    required this.target,
    required this.write,
    required this.variables,
    required this.templateId,
    this.debug = false,
  });

  factory ActionConfig.fromMap(String id, Map<dynamic, dynamic> map) {
    return ActionConfig(
      id: id,
      description: map.getString('description', fallback: 'Fix issue'),
      trigger: ActionTrigger.fromMap(map.getMap('trigger')),
      source: ActionSource.fromMap(map.getMap('source')),
      target: ActionTarget.fromMap(map.getMap('target')),
      write: ActionWrite.fromMap(map.getMap('write')),
      variables: _parseVariables(map['variables']),
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
  final String? element;
  final String? errorCode;

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
class ActionSource {
  final ActionScope scope;
  final String? component;
  final String? element;

  const ActionSource({this.scope = ActionScope.current, this.component, this.element});

  factory ActionSource.fromMap(Map<String, dynamic> map) => ActionSource(
    scope: ActionScope.fromKey(map.tryGetString('scope')),
    component: map.tryGetString('component'),
    element: map.tryGetString('element'),
  );
}

@immutable
class ActionTarget {
  final ActionScope scope;
  final String? component;
  final String? element;

  const ActionTarget({this.scope = ActionScope.related, this.component, this.element});

  factory ActionTarget.fromMap(Map<String, dynamic> map) {
    return ActionTarget(
      scope: ActionScope.fromKey(map.tryGetString('scope')),
      component: map.tryGetString('component'),
      element: map.tryGetString('element'),
    );
  }
}

@immutable
class ActionWrite {
  final WriteStrategy strategy;
  final WritePlacement placement;
  final String? filename; // Moved here

  const ActionWrite({
    this.strategy = WriteStrategy.file,
    this.placement = WritePlacement.end,
    this.filename,
  });

  factory ActionWrite.fromMap(Map<String, dynamic> map) {
    return ActionWrite(
      // FIX: Use null coalescing to ensure non-nullable fields
      strategy: WriteStrategy.fromKey(map.tryGetString('strategy')) ?? WriteStrategy.file,
      placement: WritePlacement.fromKey(map.tryGetString('placement')) ?? WritePlacement.end,
      filename: map.tryGetString('filename'),
    );
  }
}
