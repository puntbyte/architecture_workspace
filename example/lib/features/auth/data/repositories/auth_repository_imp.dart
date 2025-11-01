import 'package:fpdart/fpdart.dart';

import '../../../../core/utils/types.dart';
import '../../domain/contracts/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  FutureEither<User> getUser(int id) async {
    return Right(User(id: '1', name: 'test'));
  }

  @override
  FutureEither<void> saveUser({required String name, required String password}) async {
    return const Right(null);
  }

  @override
  FutureEither<User?> getCurrentUser() async => const Right(null);
}
