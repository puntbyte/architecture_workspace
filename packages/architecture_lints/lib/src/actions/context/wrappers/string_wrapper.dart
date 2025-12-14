import 'package:expressions/expressions.dart';
import 'package:meta/meta.dart';
import 'package:recase/recase.dart';

@immutable
class StringWrapper {
  final String value;

  const StringWrapper(this.value);

  static MemberAccessor<StringWrapper> get accessor =>
      const MemberAccessor<StringWrapper>.fallback(_getMember);

  static dynamic _getMember(StringWrapper obj, String name) => switch (name) {
    'pascalCase' => obj.pascalCase,
    'snakeCase' => obj.snakeCase,
    'camelCase' => obj.camelCase,
    'constantCase' => obj.constantCase,
    'dotCase' => obj.dotCase,
    'pathCase' => obj.pathCase,
    'paramCase' => obj.paramCase,
    'headerCase' => obj.headerCase,
    'titleCase' => obj.titleCase,
    'sentenceCase' => obj.sentenceCase,
    'length' => obj.length,
    'isEmpty' => obj.isEmpty,
    'isNotEmpty' => obj.isNotEmpty,
    'value' => obj.value,
    'toString' => obj.toString,
    'replace' => obj.replace,
    _ => throw ArgumentError('Unknown StringWrapper property => $name'),
  };

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
