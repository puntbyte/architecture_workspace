// example/lib/features/auth/domain/contracts/contracts.violations.dart

import 'package:example/core/repository/repository.dart';
import 'package:example/core/utils/types.dart';
// VIOLATION: enforce_layer_independence (domain cannot import from data)
import 'package:example/features/auth/data/models/user_model.dart'; // <-- LINT WARNING HERE
import 'package:example/features/auth/domain/entities/user.dart';

// VIOLATION: enforce_naming_conventions (name does not match '{{name}}Repository')
// VIOLATION: enforce_repository_contract (does not implement 'Repository')
abstract interface class Auth {} // <-- LINT WARNING HERE (multiple)

// VIOLATION: enforce_repository_contract (does not implement 'Repository')
abstract interface class AnalyticsRepository {} // <-- LINT WARNING HERE

// ISSUE: enforce_type_safety is not flagging the following class but it should
abstract interface class BadReturnTypeRepository implements Repository {
  // VIOLATION: enforce_type_safety (returns Future instead of FutureEither) (not working)
  Future<User> getUser(int id); // <-- LINT WARNING HERE
}

abstract interface class ImpureRepository implements Repository {
  // VIOLATION: disallow_model_in_domain (uses a Model in the return type)
  FutureEither<UserModel> getUser(int id); // <-- LINT WARNING HERE
}
