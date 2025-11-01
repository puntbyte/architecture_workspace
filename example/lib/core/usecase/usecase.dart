// Base class for all use cases, used by the `enforce_use_case_inheritance` lint.
import '../repository/repository.dart';
import '../utils/types.dart';

abstract interface class Usecase {
  final Repository repository;

  const Usecase(this.repository);
}

abstract interface class UnaryUsecase<ReturnType, ParameterType> extends Usecase {
  const UnaryUsecase(super.repository);

  FutureEither<ReturnType> call(ParameterType parameter);
}

abstract interface class NullaryUsecase<ReturnType> extends Usecase {
  const NullaryUsecase(super.repository);

  FutureEither<ReturnType> call();
}
