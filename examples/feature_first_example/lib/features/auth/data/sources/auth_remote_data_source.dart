
import 'package:example/features/auth/data/models/user_model.dart';

import 'package:example/features/auth/data/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  // DataSources return raw Futures (exceptions allowed here).
  Future<UserModel> login(String user, String pass);
}

class DefaultAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String user, String pass) async {
    return UserModel(id: '1', username: user);
  }
}

abstract interface class AuthRemoteDataSource {
  Future<UserModel> getUser(int id);
}

class DefaultAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> getUser(int id) async {
    await Future.delayed.call(const Duration(seconds: 1));
    return UserModel(id: '$id', names: 'Correct User (from API)');
  }
}
