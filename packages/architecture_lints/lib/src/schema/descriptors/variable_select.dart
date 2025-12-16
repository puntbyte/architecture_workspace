import 'package:architecture_lints/src/schema/definitions/variable_definition.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class VariableSelect {
  final String? condition; // 'if'
  final VariableDefinition result; // 'then' / 'value' / 'else'

  const VariableSelect({required this.result, this.condition});

  factory VariableSelect.fromMap(Map<dynamic, dynamic> map) {
    final condition = map.tryGetString('if');

    // The result can be in 'then', 'value', or 'else'.
    // We treat the value as a sub-config (so it can be complex).
    final rawResult = map['then'] ?? map['value'] ?? map['else'];

    return VariableSelect(
      condition: condition,
      result: VariableDefinition.fromDynamic(rawResult),
    );
  }
}
