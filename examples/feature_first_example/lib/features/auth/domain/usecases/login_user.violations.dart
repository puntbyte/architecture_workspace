import 'package:example/core/usecase/usecase.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/data/repositories/auth_repository_imp.dart';
import 'package:fpdart/fpdart.dart';

// LINT: enforce_semantic_naming
// Reason: Grammar violation. Should be 'LoginUser' (VerbNoun), not 'UserLogin' (NounVerb).
class UserLogin implements NullaryUsecase<void> {
  @override
  FutureEither<void> call() async => right(null);
}

// LINT: enforce_use_case_contract
// Reason: Must extend UnaryUsecase or NullaryUsecase.
class RandomLogic {
  void execute() {}
}

// LINT: enforce_abstract_repository_dependency
// Reason: Domain must depend on Interfaces (Ports), not Concrete Repositories.
class BadDependencyUseCase {
  final DefaultAuthRepository repo; // <-- Violation
  BadDependencyUseCase(this.repo);
}