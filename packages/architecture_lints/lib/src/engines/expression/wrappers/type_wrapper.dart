import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/generic_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/engines/expression/wrappers/string_wrapper.dart';
import 'package:expressions/expressions.dart';

class TypeWrapper {
  final DartType? type;
  final String rawString;
  final Map<String, TypeDefinition> definitions;

  const TypeWrapper(
    this.type, {
    this.rawString = '',
    this.definitions = const {},
  });

  static MemberAccessor<TypeWrapper> get accessor =>
      const MemberAccessor<TypeWrapper>.fallback(_getMember);

  static dynamic _getMember(TypeWrapper obj, String name) => switch (name) {
    'name' => obj.name,
    'generics' => obj.generics,
    'unwrapped' => obj.unwrapped,
    'innerType' => obj.innerType,
    'isFuture' => obj.isFuture,
    'importUri' => obj.importUri,
    _ => throw ArgumentError('Unknown TypeWrapper property: $name'),
  };

  StringWrapper get name {
    final t = type;

    if (t != null && t.alias != null) {
      final aliasName = t.alias!.element.name;
      var typeArgs = '';
      final aliasArgs = t.alias!.typeArguments;
      if (aliasArgs.isNotEmpty) {
        final args = aliasArgs.map((e) => e.getDisplayString()).join(', ');
        typeArgs = '<$args>';
      }

      return StringWrapper('$aliasName$typeArgs');
    }

    return StringWrapper(t?.getDisplayString() ?? rawString);
  }

  GenericWrapper? get generics {
    final t = type;
    if (t is InterfaceType) {
      if (t.typeArguments.isNotEmpty) {
        final wrappedArgs = t.typeArguments
            .map((arg) => TypeWrapper(arg, definitions: definitions))
            .toList();

        final typeName = t.element.name ?? ''; // Non-nullable in recent versions

        return GenericWrapper(
          StringWrapper(typeName),
          ListWrapper(wrappedArgs),
        );
      }
    }
    return null;
  }

  StringWrapper get unwrapped {
    if (type == null) return StringWrapper(rawString);

    var current = type!;
    var changed = true;

    while (changed) {
      changed = false;

      // 1. Unwrap Future / FutureOr
      var isAsync = current.isDartAsyncFuture || current.isDartAsyncFutureOr;
      if (!isAsync && current is InterfaceType) {
        final name = current.element.name;
        if (name == 'Future' || name == 'FutureOr') isAsync = true;
      }

      if (isAsync) {
        if (current is InterfaceType && current.typeArguments.isNotEmpty) {
          current = current.typeArguments.first;
          changed = true;
          continue;
        }
      }

      // 2. Unwrap Generic Wrappers
      if (current is InterfaceType && current.typeArguments.isNotEmpty) {
        final name = current.element.name;
        const collections = {'List', 'Map', 'Set', 'Iterable', 'Stream'};
        if (collections.contains(name)) break;

        if (current.typeArguments.length == 1) {
          current = current.typeArguments.first;
          changed = true;
        } else if (current.typeArguments.length == 2) {
          current = current.typeArguments.last;
          changed = true;
        }
      }
    }

    return StringWrapper(current.getDisplayString());
  }

  StringWrapper get innerType => unwrapped;

  bool get isFuture => name.value.startsWith('Future');

  StringWrapper get importUri {
    if (type?.alias != null) return _uriFromElement(type!.alias!.element);
    if (type?.element != null) return _uriFromElement(type!.element);
    return const StringWrapper('');
  }

  StringWrapper _uriFromElement(Element? element) {
    if (element == null) return const StringWrapper('');
    final lib = element.library;
    if (lib == null) return const StringWrapper('');
    final uri = lib.firstFragment.source.uri.toString();
    if (uri == 'dart:core') return const StringWrapper('');
    return StringWrapper(uri);
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'generics': generics?.toMap(),
    'unwrapped': unwrapped,
    'innerType': innerType,
    'isFuture': isFuture,
    'importUri': importUri,
    'value': toString(),
  };

  @override
  String toString() => name.value;

  String operator +(Object other) => toString() + other.toString();
}
