import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';

class GenericWrapper {
  /// The base type name (e.g. "Future", "Either", "Map").
  final StringWrapper base;

  /// The list of generic arguments (e.g. [String, int]).
  final ListWrapper<TypeWrapper> args;

  const GenericWrapper(this.base, this.args);

  // --- Convenience Properties for Expressions ---

  /// Returns the first argument (e.g. T in Future< T >).
  TypeWrapper? get first => args.isNotEmpty ? args.first : null;

  /// Returns the last argument (e.g. R in Either< L, R >).
  TypeWrapper? get last => args.isNotEmpty ? args.last : null;

  /// Number of generic arguments.
  int get length => args.length;

  /// Converts to Map for Mustache.
  Map<String, dynamic> toMap() {
    return {
      'base': base,
      'args': args, // ListWrapper will be handled by accessors
      'length': length,
    };
  }
}
