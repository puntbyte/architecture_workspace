// example/lib/features/auth/domain/contracts/auth_repository.violations.dart

import '../../../../core/repository/repository.dart';
import '../../../../core/utils/types.dart';
// VIOLATION: enforce_layer_independence (importing from the data layer)
import '../../data/model/user_model.dart';
import '../entities/user.dart';

// VIOLATION: enforce_repository_inheritance (does not extend Repository)
abstract interface class IAnalyticsRepository {
  void getUser(int id);
}

// VIOLATION: enforce_custom_return_type (returns Future<User> instead of FutureEither)
abstract interface class BadReturnTypeRepository implements Repository {
  Future<User> getUser(int id); // <-- LINT WARNING HERE
}

// VIOLATION: enforce_naming_conventions (name does not end with "Repository")
abstract interface class AuthRepo implements Repository {} // <-- LINT WARNING HERE

abstract interface class BadSignatureRepository implements Repository {
  // VIOLATION: domain_layer_purity (uses a Model in a return type)
  FutureEither<UserModel> getUser(int id); // <-- LINT ERROR HERE

  // VIOLATION: domain_layer_purity (uses a Model in a parameter)
  FutureEither<void> saveUser(UserModel user); // <-- LINT ERROR HERE
}
