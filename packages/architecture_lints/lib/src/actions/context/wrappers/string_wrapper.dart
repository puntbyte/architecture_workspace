import 'package:expressions/expressions.dart';
import 'package:meta/meta.dart';
import 'package:recase/recase.dart';

@immutable
class StringWrapper {
  final String value;

  const StringWrapper(this.value);

  static MemberAccessor<StringWrapper> get accessor =>
      MemberAccessor<StringWrapper>.fallback(_getMember);

  static dynamic _getMember(StringWrapper obj, String name) {
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
      case 'replace': return obj.replace;
      default: throw ArgumentError('Unknown StringWrapper property: $name');
    }
  }

  String get pascalCase => ReCase(value).pascalCase;
  String get snakeCase => ReCase(value).snakeCase;
  String get camelCase => ReCase(value).camelCase;
  String get constantCase => ReCase(value).constantCase;
  String get dotCase => ReCase(value).dotCase;
  String get pathCase => ReCase(value).pathCase;
  String get paramCase => ReCase(value).paramCase;
  String get headerCase => ReCase(value).headerCase;
  String get titleCase => ReCase(value).titleCase;
  String get sentenceCase => ReCase(value).sentenceCase;

  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
  int get length => value.length;

  String replace(String from, String replace) => value.replaceAll(from, replace);

  Map<String, dynamic> toMap() => {
    'value': value,
    'pascalCase': pascalCase,
    'snakeCase': snakeCase,
    'camelCase': camelCase,
    'length': length,
  };

  @override
  bool operator ==(Object other) {
    if (other is String) return value == other;
    if (other is StringWrapper) return value == other.value;
    return false;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}