import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/actions/context/wrappers/generic_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';

class TypeWrapper {
  final DartType? type;
  final String rawString;
  final Map<String, Definition> definitions;

  TypeWrapper(this.type, {
    this.rawString = '',
    this.definitions = const {},
  });

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
    // FIX: Capture local variable for type promotion
    final t = type;

    if (t is InterfaceType) {
      if (t.typeArguments.isNotEmpty) {
        // Recursively wrap arguments
        final wrappedArgs = t.typeArguments
            .map((arg) => TypeWrapper(arg, definitions: definitions))
            .toList();

        final typeName = t.element.name ?? '';

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

    // Loop to peel off multiple layers (e.g. Future<Either<L, R>> -> Either<L, R> -> R)
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

      // 2. Unwrap Generic Wrappers (Heuristic)
      if (current is InterfaceType && current.typeArguments.isNotEmpty) {
        final name = current.element.name;

        // STOP if it is a standard collection
        const collections = {'List', 'Map', 'Set', 'Iterable', 'Stream'};
        if (collections.contains(name)) {
          break;
        }

        if (current.typeArguments.length == 1) {
          current = current.typeArguments.first;
          changed = true;
        }
        else if (current.typeArguments.length == 2) {
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
    // Priority: Alias -> Element -> None
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'generics': generics?.toMap(),
      'unwrapped': unwrapped,
      'innerType': innerType,
      'isFuture': isFuture,
      'importUri': importUri,
      'value': toString(),
    };
  }

  @override
  String toString() => name.value;

  String operator +(Object other) => toString() + other.toString();
}
