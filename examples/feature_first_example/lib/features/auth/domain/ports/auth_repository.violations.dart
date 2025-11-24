// example/lib/features/auth/domain/contracts/auth_repository.violations.dart

import 'package:example/core/repository/repository.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/data/models/user_model.dart';
// LINT: disallow_model_in_domain
// Reason: Domain cannot know about Data Models.import 'package:example/features/auth/data/models/user_model.dart';
import 'package:example/features/auth/domain/entities/user.violations.dart';
import 'package:example/features/auth/domain/entities/user.dart';

// LINT: enforce_naming_conventions
// Reason: Must end with 'Repository'.
abstract interface class AuthRepo implements Repository {

  // LINT: enforce_type_safety
  // Reason: Must return FutureEither, not raw Future.
  Future<User> login(String username);

  // LINT: disallow_model_in_domain
  // Reason: Returning a Model in the domain.
  Future<UserModel> unsafeLogin();
}

// LINT: enforce_repository_contract
// Reason: Must extend base `Repository`.
abstract interface class BadInheritanceRepository {
  void doSomething();
}

// VIOLATION: enforce_repository_inheritance (does not extend Repository)
abstract interface class IAnalyticsRepository {
  void getUser(int id);
}

// VIOLATION: enforce_custom_return_type (returns Future<User> instead of FutureEither)
abstract interface class BadReturnTypeRepository implements Repository {
  Future<UserEntity> getUser(int id); // <-- LINT WARNING HERE
}

abstract interface class BadSignatureRepository implements Repository {
  // VIOLATION: disallow_model_in_domain (uses a Model in a return type)
  FutureEither<UserModel> getUser(int id); // <-- LINT ERROR HERE

  // VIOLATION: disallow_model_in_domain (uses a Model in a parameter)
  FutureEither<void> saveUser(UserModel user); // <-- LINT ERROR HERE
}
