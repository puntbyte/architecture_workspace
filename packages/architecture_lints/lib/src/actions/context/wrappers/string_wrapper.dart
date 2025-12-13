// lib/src/actions/context/wrappers/string_wrapper.dart
import 'package:meta/meta.dart';
import 'package:recase/recase.dart';

@immutable
class StringWrapper {
  final String value;

  const StringWrapper(this.value);

  // CRITICAL FIX: Return 'String' (primitive), not 'StringWrapper'.
  // This enables standard binary expressions like: '_' + source.name.camelCase
  // because the expression engine knows how to add Strings.

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

  // Primitives
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
  int get length => value.length;

  /// Converts the wrapper to a Map (fallback for Mustache if unwrapping fails).
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

  // Support: wrapper + 'suffix'
  String operator +(Object other) => value + other.toString();
}
