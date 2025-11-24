// lib/core/utils/types.dart
import 'package:fpdart/fpdart.dart';

class Failure {
  final String message;
  const Failure(this.message);
}

/// Standard wrapper for async operations.
typedef FutureEither<T> = Future<Either<Failure, T>>;

/// Strong types for IDs to avoid primitive obsession.
typedef IntId = int;
typedef StringId = String;
