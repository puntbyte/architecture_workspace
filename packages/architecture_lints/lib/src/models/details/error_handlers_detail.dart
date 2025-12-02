// lib/src/models/detail/error_handlers_detail.dart

part of '../configs/error_handlers_config.dart';

/// Represents a specific operation rule (e.g., "try_return Object").
class OperationDetail {
  final List<String> operations; // Supports single string or list ['throw', 'rethrow']
  final String? targetType; // Key referencing type_definitions (e.g. 'exception.base')

  const OperationDetail({required this.operations, this.targetType});

  factory OperationDetail.fromMap(Map<String, dynamic> map) {
    final op = map[ConfigKey.error.operation];
    final opList = op is List ? op.cast<String>() : [op.toString()];

    return OperationDetail(
      operations: opList,
      targetType: map.asStringOrNull(ConfigKey.error.targetType),
    );
  }
}

/// Represents a conversion rule (e.g., Exception -> Failure).
class ConversionDetail {
  final String fromType;
  final String toType;

  const ConversionDetail({required this.fromType, required this.toType});

  factory ConversionDetail.fromMap(Map<String, dynamic> map) {
    return ConversionDetail(
      fromType: map.asString(ConfigKey.error.fromType),
      toType: map.asString(ConfigKey.error.toType),
    );
  }
}
