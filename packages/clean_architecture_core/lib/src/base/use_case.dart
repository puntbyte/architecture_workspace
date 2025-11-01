import 'package:clean_architecture_core/clean_architecture_core.dart';

/// {@template use_case}
/// An abstract interface class that holds a [Repository].
///
/// This is a base class for all use cases. It ensures that all use cases have a repository, which
/// is responsible for providing data.
/// {@endtemplate}
abstract interface class UseCase {
  /// The repository for this use case.
  final Repository repository;

  /// {@macro use_case}
  const UseCase(this.repository);
}

/// {@template nullary_use_case}
/// An abstract interface class for a use case that takes no parameters.
/// {@endtemplate}
abstract interface class NullaryUseCase<ReturnType> extends UseCase {
  /// {@macro nullary_use_case}
  const NullaryUseCase(super.repository);

  /// Executes the use case.
  FutureEither<ReturnType> call();
}

/// {@template unary_use_case}
/// An abstract interface class for a use case that takes one parameter.
/// {@endtemplate}
abstract interface class UnaryUseCase<ReturnType, ParameterType> extends UseCase {
  /// {@macro unary_use_case}
  const UnaryUseCase(super.repository);

  /// Executes the use case.
  FutureEither<ReturnType> call(ParameterType parameter);
}
