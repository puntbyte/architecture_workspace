// example/lib/features/auth/domain/usecases/usecases.violations.dart

import 'package:example/core/repository/repository.dart';
import 'package:example/core/usecase/usecase.dart';
import 'package:example/core/utils/types.dart';
// VIOLATION: enforce_layer_independence (domain cannot import from data)
import 'package:example/features/auth/data/repositories/default_auth_repository.dart';

// VIOLATION: enforce_use_case_inheritance (does not implement a base Usecase)
class OrphanGetUser {} // <-- LINT WARNING HERE

// enforce_naming_conventions does not work when there is naming_convention ambiguity.
// VIOLATION: enforce_naming_conventions (name 'GetUserUsecase' does not match '{{name}}')
class GetUserUsecase implements UnaryUsecase<void, int> { // <-- LINT WARNING HERE (not working)
  @override
  // VIOLATION: enforce_custom_return_type (return type 'dynamic' is not a custom type)
  dynamic noSuchMethod(Invocation invocation) { // <-- LINT WARNING HERE
    return super.noSuchMethod(invocation);
  }
}

// VIOLATION: enforce_naming_conventions (the message is not correct)
class BadDependencyUsecase implements UnaryUsecase<void, int> { // <-- LINT WARNING HERE
  // VIOLATION: enforce_abstract_repository_dependency
  final DefaultAuthRepository _repository; // <-- LINT WARNING HERE

  BadDependencyUsecase(this._repository); // <-- LINT WARNING HERE

  @override
  FutureEither<void> call(int params) => throw UnimplementedError();
}
