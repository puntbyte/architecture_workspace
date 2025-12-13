import 'package:architecture_lints/src/actions/context/wrappers/config_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/generic_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/method_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/node_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/parameter_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:expressions/expressions.dart';

class ArchitectureMemberAccessors {
  const ArchitectureMemberAccessors._();

  static List<MemberAccessor<dynamic>> getAll() => [
    const MemberAccessor<MethodWrapper>.fallback(_getMethodMember),
    const MemberAccessor<ParameterWrapper>.fallback(_getParameterMember),
    const MemberAccessor<NodeWrapper>.fallback(_getNodeMember),
    const MemberAccessor<TypeWrapper>.fallback(_getTypeMember),
    const MemberAccessor<StringWrapper>.fallback(_getStringMember),
    const MemberAccessor<GenericWrapper>.fallback(_getGenericMember),
    const MemberAccessor<ListWrapper>.fallback(_getListMember),
    const MemberAccessor<ConfigWrapper>.fallback(_getConfigMember),
    const MemberAccessor<Definition>.fallback(_getDefinitionMember),
    MemberAccessor.mapAccessor,
  ];

  static dynamic _getListMember(ListWrapper obj, String name) {
    switch (name) {
      case 'hasMany': return obj.hasMany;
      case 'isSingle': return obj.isSingle;
      case 'isEmpty': return obj.isEmpty;
      case 'isNotEmpty': return obj.isNotEmpty;
      case 'length': return obj.length;
      case 'first': return obj.first;
      case 'last': return obj.last;
      case 'at': return obj.at;
      default: throw ArgumentError('Unknown ListWrapper property: $name');
    }
  }

  static dynamic _getStringMember(StringWrapper obj, String name) {
    switch (name) {
      case 'pascalCase': return obj.pascalCase;
      case 'snakeCase': return obj.snakeCase;
      case 'camelCase': return obj.camelCase;
      case 'constantCase': return obj.constantCase;
      case 'dotCase': return obj.dotCase;
      case 'pathCase': return obj.pathCase;
      case 'paramCase': return obj.paramCase;
      case 'headerCase': return obj.headerCase;
      case 'titleCase': return obj.titleCase;
      case 'sentenceCase': return obj.sentenceCase;
      case 'length': return obj.length;
      case 'isEmpty': return obj.isEmpty;
      case 'isNotEmpty': return obj.isNotEmpty;
      case 'value': return obj.value;
      case 'toString': return obj.toString;
      default: throw ArgumentError('Unknown StringWrapper property: $name');
    }
  }

  static dynamic _getTypeMember(TypeWrapper obj, String name) {
    switch (name) {
      case 'name': return obj.name;
      case 'generics': return obj.generics;
      case 'unwrapped': return obj.unwrapped;
      case 'innerType': return obj.innerType;
      case 'isFuture': return obj.isFuture;
      case 'importUri': return obj.importUri;
      default: throw ArgumentError('Unknown TypeWrapper property: $name');
    }
  }

  static dynamic _getGenericMember(GenericWrapper obj, String name) {
    switch (name) {
      case 'base': return obj.base;
      case 'args': return obj.args;
      case 'first': return obj.first;
      case 'last': return obj.last;
      case 'length': return obj.length;
      default: throw ArgumentError('Unknown GenericWrapper property: $name');
    }
  }

  static dynamic _getMethodMember(MethodWrapper obj, String name) {
    switch (name) {
      case 'returnType': return obj.returnType;
      case 'returnTypeInner': return obj.returnTypeInner;
      case 'parameters': return obj.parameters;
      default: return _getNodeMember(obj, name);
    }
  }

  static dynamic _getParameterMember(ParameterWrapper obj, String name) {
    switch (name) {
      case 'type': return obj.type;
      case 'isNamed': return obj.isNamed;
      case 'isPositional': return obj.isPositional;
      case 'isRequired': return obj.isRequired;
      default: return _getNodeMember(obj, name);
    }
  }

  static dynamic _getNodeMember(NodeWrapper obj, String name) {
    switch (name) {
      case 'name': return obj.name;
      case 'parent': return obj.parent;
      case 'file': return {'path': obj.filePath};
      case 'filePath': return obj.filePath;
      default: throw ArgumentError('Property "$name" not found on ${obj.runtimeType}');
    }
  }

  static dynamic _getConfigMember(ConfigWrapper obj, String name) {
    switch (name) {
      case 'definitions': return obj.definitions;
      case 'annotationsFor': return obj.annotationsFor;
      case 'definitionFor': return obj.definitionFor;
      case 'namesFor': return obj.namesFor;
      default: throw ArgumentError('Unknown ConfigWrapper property: $name');
    }
  }

  static dynamic _getDefinitionMember(Definition obj, String name) {
    switch (name) {
      case 'type': return obj.type;
      case 'types': return obj.types;
      case 'import': return obj.import;
      case 'imports': return obj.imports;
      default: throw ArgumentError('Unknown Definition property: $name');
    }
  }
}