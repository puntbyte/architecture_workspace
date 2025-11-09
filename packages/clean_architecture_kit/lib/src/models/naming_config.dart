// lib/src/models/naming_config.dart

import 'package:clean_architecture_kit/src/models/rules/naming_rule.dart';

/// A strongly-typed representation of the `naming_conventions` block in `analysis_options.yaml`.
class NamingConfig {
  final NamingRule entity;
  final NamingRule model;
  final NamingRule useCase;
  final NamingRule useCaseRecordParameter;

  final NamingRule dataSourceInterface;
  final NamingRule dataSourceImplementation;

  final NamingRule repositoryInterface;
  final NamingRule repositoryImplementation;

  const NamingConfig({
    required this.entity,
    required this.model,
    required this.useCase,
    required this.useCaseRecordParameter,
    required this.dataSourceInterface,
    required this.dataSourceImplementation,
    required this.repositoryInterface,
    required this.repositoryImplementation,
  });

  factory NamingConfig.fromMap(Map<String, dynamic> map) {
    return NamingConfig(
      entity: NamingRule.from(map['entity'], '{{name}}'),
      model: NamingRule.from(map['model'], '{{name}}Model'),
      useCase: NamingRule.from(map['use_case'], '{{name}}'),
      useCaseRecordParameter: NamingRule.from(map['use_case_record_parameter'], '_{{name}}Params'),
      repositoryInterface: NamingRule.from(map['repository_interface'], '{{name}}Repository'),
      repositoryImplementation: NamingRule.from(
        map['repository_implementation'],
        '{{type}}{{name}}Repository',
      ),
      dataSourceInterface: NamingRule.from(map['data_source_interface'], '{{name}}DataSource'),
      dataSourceImplementation: NamingRule.from(
        map['data_source_implementation'],
        'Default{{name}}DataSource',
      ),
    );
  }
}
