import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/wrappers/node_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';

class ParameterWrapper extends NodeWrapper {
  final FormalParameter param;

  ParameterWrapper(this.param, {super.definitions = const {}}) : super(param);

  @override
  StringWrapper get name {
    final token = param.name;
    return StringWrapper(token?.lexeme ?? '');
  }

  TypeWrapper get type {
    final t = param.declaredFragment?.element.type;
    return TypeWrapper(t, rawString: 'dynamic', definitions: definitions);
  }

  bool get isNamed => param.isNamed;
  bool get isPositional => param.isPositional;
  bool get isRequired => param.isRequired;

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'isNamed': isNamed,
      'isPositional': isPositional,
      'isRequired': isRequired,
    };
  }
}