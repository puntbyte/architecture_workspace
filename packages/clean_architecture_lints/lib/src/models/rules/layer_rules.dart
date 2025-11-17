// lib/src/models/rules/layer_rules.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// Represents the configuration for the domain layer directories.
class DomainLayerRule {
  final List<String> entity;
  final List<String> contract;
  final List<String> usecase;

  const DomainLayerRule({
    required this.entity,
    required this.contract,
    required this.usecase,
  });

  factory DomainLayerRule.fromMap(Map<String, dynamic> map) {
    return DomainLayerRule(
      entity: map.getList('entity', orElse: ['entities']),
      contract: map.getList('contract', orElse: ['contracts']),
      usecase: map.getList('usecase', orElse: ['usecases']),
    );
  }
}

/// Represents the configuration for the data layer directories.
class DataLayerRule {
  final List<String> model;
  final List<String> repository;
  final List<String> source;

  const DataLayerRule({
    required this.model,
    required this.repository,
    required this.source,
  });

  factory DataLayerRule.fromMap(Map<String, dynamic> map) {
    return DataLayerRule(
      model: map.getList('model', orElse: ['models']),
      repository: map.getList('repository', orElse: ['repositories']),
      source: map.getList('source', orElse: ['sources']),
    );
  }
}

/// Represents the configuration for the presentation layer directories.
class PresentationLayerRule {
  final List<String> page;
  final List<String> widget;
  final List<String> manager;

  const PresentationLayerRule({
    required this.page,
    required this.widget,
    required this.manager,
  });

  factory PresentationLayerRule.fromMap(Map<String, dynamic> map) {
    return PresentationLayerRule(
      page: map.getList('page', orElse: ['pages']),
      widget: map.getList('widget', orElse: ['widgets']),
      manager: map.getList('manager', orElse: ['managers', 'bloc', 'cubit']),
    );
  }
}
