// lib/src/models/naming_config.dart

import 'package:clean_architecture_kit/src/utils/json_map_extension.dart';

/// Represents a single naming rule with allowed and forbidden patterns.
class NamingRule {
  final String pattern;
  final List<String> antiPatterns;

  const NamingRule({required this.pattern, this.antiPatterns = const []});

  factory NamingRule.from(dynamic data, String defaultPattern) {
    if (data is String) return NamingRule(pattern: data);

    if (data is Map<String, dynamic>) {
      return NamingRule(
        pattern: data.getString('pattern', defaultPattern),
        antiPatterns: data.getList('anti_pattern'), // CORRECTED
      );
    }

    return NamingRule(pattern: defaultPattern);
  }
}

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
      repositoryImplementation: NamingRule.from(map['repository_implementation'], '{{type}}{{name}}Repository'),
      dataSourceInterface: NamingRule.from(map['data_source_interface'], '{{name}}DataSource'),
      dataSourceImplementation: NamingRule.from(map['data_source_implementation'], 'Default{{name}}DataSource'),
    );
  }
}
