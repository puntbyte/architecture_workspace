// lib/src/engines/expression/

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
    // Properties
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

    // Methods (Return functions)
    'replace' => obj.replace,
    'replaceAll' => obj.replaceAll,
    'substring' => obj.substring,
    'toLowerCase' => obj.toLowerCase,
    'toUpperCase' => obj.toUpperCase,
    'trim' => obj.trim,
    'contains' => obj.contains,
    'startsWith' => obj.startsWith,
    'endsWith' => obj.endsWith,
    'toString' => obj.toString,

    _ => throw ArgumentError('Unknown StringWrapper property/method: $name'),
  };

  // --- ReCase Properties ---
  StringWrapper get pascalCase => StringWrapper(ReCase(value).pascalCase);

  StringWrapper get snakeCase => StringWrapper(ReCase(value).snakeCase);

  StringWrapper get camelCase => StringWrapper(ReCase(value).camelCase);

  StringWrapper get constantCase => StringWrapper(ReCase(value).constantCase);

  StringWrapper get dotCase => StringWrapper(ReCase(value).dotCase);

  StringWrapper get pathCase => StringWrapper(ReCase(value).pathCase);

  StringWrapper get paramCase => StringWrapper(ReCase(value).paramCase);

  StringWrapper get headerCase => StringWrapper(ReCase(value).headerCase);

  StringWrapper get titleCase => StringWrapper(ReCase(value).titleCase);

  StringWrapper get sentenceCase => StringWrapper(ReCase(value).sentenceCase);

  // --- Standard Properties ---
  bool get isEmpty => value.isEmpty;

  bool get isNotEmpty => value.isNotEmpty;

  int get length => value.length;

  // --- Methods (Exposed to Expression Engine) ---
  StringWrapper replace(String from, String replace) =>
      StringWrapper(value.replaceAll(from, replace)); // Alias for replaceAll

  StringWrapper replaceAll(Pattern from, String replace) =>
      StringWrapper(value.replaceAll(from, replace));

  StringWrapper substring(int start, [int? end]) => StringWrapper(value.substring(start, end));

  StringWrapper toLowerCase() => StringWrapper(value.toLowerCase());

  StringWrapper toUpperCase() => StringWrapper(value.toUpperCase());

  StringWrapper trim() => StringWrapper(value.trim());

  bool contains(Pattern other) => value.contains(other);

  bool startsWith(Pattern other) => value.startsWith(other);

  bool endsWith(String other) => value.endsWith(other);

  /// Helper for debugging and templates: returns a plain Map of useful string forms.
  Map<String, dynamic> toMap() => {
    'value': value,
    'pascalCase': pascalCase.value,
    'snakeCase': snakeCase.value,
    'camelCase': camelCase.value,
    'constantCase': constantCase.value,
    'dotCase': dotCase.value,
    'pathCase': pathCase.value,
    'paramCase': paramCase.value,
    'headerCase': headerCase.value,
    'titleCase': titleCase.value,
    'sentenceCase': sentenceCase.value,
    'length': length,
    'isEmpty': isEmpty,
    'isNotEmpty': isNotEmpty,
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
