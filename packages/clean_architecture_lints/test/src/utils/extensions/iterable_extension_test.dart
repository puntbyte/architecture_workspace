// test/src/utils/extensions/iterable_extension_test.dart

import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:test/test.dart';

// A simple helper class for testing with objects.
class _User {
  final int id;
  final String name;
  const _User(this.id, this.name);
}

void main() {
  group('IterableExtension', () {
    group('firstWhereOrNull', () {
      final numbers = [10, 20, 30, 40, 50];
      final users = [
        const _User(1, 'Alice'),
        const _User(2, 'Bob'),
        const _User(3, 'Charlie'),
      ];

      test('should return the first element that satisfies the predicate', () {
        // Find the first number greater than 25.
        final result = numbers.firstWhereOrNull((n) => n > 25);
        expect(result, 30);
      });

      test('should return the first element of the list when it matches', () {
        final result = numbers.firstWhereOrNull((n) => n == 10);
        expect(result, 10);
      });

      test('should return the last element of the list when only it matches', () {
        final result = numbers.firstWhereOrNull((n) => n == 50);
        expect(result, 50);
      });

      test('should return null when no element satisfies the predicate', () {
        // Find a number greater than 100 in the list.
        final result = numbers.firstWhereOrNull((n) => n > 100);
        expect(result, isNull);
      });

      test('should return null when the iterable is empty', () {
        final emptyList = <int>[];
        final result = emptyList.firstWhereOrNull((n) => n > 0);
        expect(result, isNull);
      });

      test('should return the correct object from a list of objects', () {
        final result = users.firstWhereOrNull((user) => user.name == 'Bob');
        expect(result, isNotNull);
        expect(result?.id, 2);
        expect(result?.name, 'Bob');
      });

      test('should return null when no object is found in a list of objects', () {
        final result = users.firstWhereOrNull((user) => user.name == 'David');
        expect(result, isNull);
      });
    });
  });
}
