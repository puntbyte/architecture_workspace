// lib/src/models/rules/presentation_layer_rule.dart

part of 'package:clean_architecture_lints/src/models/layer_config.dart';

/// Represents the configuration for the domain layer directories.
class DomainLayerRule {
  final List<String> entity;
  final List<String> usecase;
  final List<String> port;

  const DomainLayerRule({
    required this.entity,
    required this.usecase,
    required this.port,
  });

  factory DomainLayerRule.fromMap(Map<String, dynamic> map) {
    return DomainLayerRule(
      entity: map.asStringList(ConfigKey.layer.entity, orElse: [ConfigKey.layer.entityDir]),
      usecase: map.asStringList(ConfigKey.layer.usecase, orElse: [ConfigKey.layer.usecaseDir]),
      port: map.asStringList(ConfigKey.layer.port, orElse: [ConfigKey.layer.portDir]),
    );
  }
}
