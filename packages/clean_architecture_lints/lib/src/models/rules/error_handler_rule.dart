// lib/src/models/rules/error_handler_rule.dart

part of '../configs/error_handlers_config.dart';

/// Represents the error handling strategy for a specific component.
class ErrorHandlerRule {
  final String on;
  final String role;
  final List<OperationDetail> required;
  final List<OperationDetail> forbidden;
  final List<ConversionDetail> conversions;

  const ErrorHandlerRule({
    required this.on,
    required this.role,
    this.required = const [],
    this.forbidden = const [],
    this.conversions = const [],
  });

  factory ErrorHandlerRule.fromMap(Map<String, dynamic> map) {
    return ErrorHandlerRule(
      on: map.asString(ConfigKey.rule.on),
      role: map.asString(ConfigKey.error.role),
      required: map.asMapList(ConfigKey.rule.required).map(OperationDetail.fromMap).toList(),
      forbidden: map.asMapList(ConfigKey.rule.forbidden).map(OperationDetail.fromMap).toList(),
      conversions: map.asMapList(ConfigKey.error.conversions).map(ConversionDetail.fromMap).toList(),
    );
  }
}
