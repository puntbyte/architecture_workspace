// example/lib/features/auth/data/sources/auth_remote_data_source.violations.dart

import 'package:example/features/auth/domain/entities/user.dart';
import 'package:example/core/utils/types.dart';

// VIOLATION: enforce_naming_conventions (name does not match '{{name}}DataSource')
abstract interface class IAuthSource {}

abstract interface class BadSignatureDataSource {
  // VIOLATION: disallow_entity_in_data_source (returns an Entity)
  Future<User> getUser(int id);

  // VIOLATION: enforce_exception_on_data_source (should not return a FutureEither)
  FutureEither<void> saveUser();
}

class ConcreteDataSource {
  // VIOLATION: disallow_public_members_in_implementation (public member is not an override)
  void myHelper() {} // <-- LINT WARNING HERE
}
