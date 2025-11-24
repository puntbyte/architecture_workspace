// lib/features/auth/domain/ports/auth_repository.dart

import 'package:example/core/repository/repository.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/entities/user.dart';

// CORRECT: Extends Repository, returns FutureEither, naming is correct.
abstract interface class AuthRepository implements Repository {
  FutureEither<User> login(String username, String password);
  FutureEither<void> logout();
}
