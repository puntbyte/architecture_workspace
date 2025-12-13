import 'dart:collection';

/// Wraps a list to provide template-friendly properties.
/// Implements Iterable so Mustache can iterate it, but does NOT extend ListBase
/// to ensure the Expression Engine uses our custom member accessor.
class ListWrapper<E> with IterableMixin<E> {
  final List<E> _inner;

  const ListWrapper(this._inner);

  @override
  Iterator<E> get iterator => _inner.iterator;

  @override
  int get length => _inner.length;

  E operator [](int index) => _inner[index];

  // --- Rich Properties for Templates/Expressions ---

  bool get hasMany => length > 1;

  bool get isSingle => length == 1;

  // Explicitly expose these for the MemberAccessor
  @override
  bool get isEmpty => _inner.isEmpty;

  @override
  bool get isNotEmpty => _inner.isNotEmpty;

  @override
  E get first => _inner.first;

  @override
  E get last => _inner.last;

  E? at(int index) {
    if (index >= 0 && index < length) return _inner[index];
    return null;
  }

  @override
  List<E> toList({bool growable = true}) => _inner.toList(growable: growable);
}
