// lib/features/auth/domain/contracts/auth_repository.dart

import 'package:example/core/repository/repository.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/entities/user.dart';

abstract interface class AuthRepository implements Repository {
  FutureEither<User> getUser(int id);

  FutureEither<void> saveUser({required String name, required String password});
}
