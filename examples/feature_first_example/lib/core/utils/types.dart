import 'package:fpdart/fpdart.dart';

// A simple Failure class
class Failure {
  final String message;
  const Failure(this.message);
}

// The custom return type that our linter will enforce.
typedef FutureEither<T> = Future<Either<Failure, T>>;

typedef IntId = int;

typedef StringId = String;
