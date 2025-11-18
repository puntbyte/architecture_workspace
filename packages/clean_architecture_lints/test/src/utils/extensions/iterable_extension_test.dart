// test/src/utils/extensions/iterable_extension_test.dart

import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:test/test.dart';

// A simple helper class for testing with objects.
class _User {
  final int id;
  final String name;

  const _User(this.id, this.name);

  // Override equals and hashCode for reliable object comparison in tests.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _User && runtimeType == other.runtimeType && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

void main() {
  group('Iterable Extensions', () {
    group('firstWhereOrNull', () {
      late List<int> numbers;
      late List<_User> users;

      setUp(() {
        numbers = [10, 20, 30, 40, 50];
        users = [const _User(1, 'Alice'), const _User(2, 'Bob')];
      });

      test('should return the first element that satisfies the predicate', () {
        final result = numbers.firstWhereOrNull((n) => n > 25);
        expect(result, 30);
      });

      test('should return null when no element satisfies the predicate', () {
        final result = numbers.firstWhereOrNull((n) => n > 100);
        expect(result, isNull);
      });

      test('should return null when the iterable is empty', () {
        final result = <int>[].firstWhereOrNull((n) => n > 0);
        expect(result, isNull);
      });

      test('should return the correct object from a list of objects', () {
        final result = users.firstWhereOrNull((user) => user.name == 'Bob');
        expect(result, const _User(2, 'Bob'));
      });

      test('should return null when no object is found in a list of objects', () {
        final result = users.firstWhereOrNull((user) => user.name == 'David');
        expect(result, isNull);
      });
    });
  });

  group('NullableIterableExtension', () {
    group('whereNotNull', () {
      test('should return an iterable with nulls removed from the middle', () {
        final listWithNulls = [1, 2, null, 3, null, 4];
        expect(listWithNulls.whereNotNull(), orderedEquals([1, 2, 3, 4]));
      });

      test('should return an iterable with leading and trailing nulls removed', () {
        final listWithNulls = [null, 1, 2, 3, null];
        expect(listWithNulls.whereNotNull(), orderedEquals([1, 2, 3]));
      });

      test('should return an empty iterable when the original list contains only nulls', () {
        final listOfNulls = [null, null, null];
        expect(listOfNulls.whereNotNull(), isEmpty);
      });

      test('should return an empty iterable when the original list is empty', () {
        final emptyList = <int?>[];
        expect(emptyList.whereNotNull(), isEmpty);
      });

      test('should return an equivalent iterable when the original list has no nulls', () {
        final listWithoutNulls = [1, 2, 3];
        expect(listWithoutNulls.whereNotNull(), orderedEquals([1, 2, 3]));
      });
    });
  });
}
