// example/lib/features/auth/data/repositories/auth_repository.dart

import 'package:clean_feature_first/core/error/exceptions.dart';
import 'package:clean_feature_first/core/error/failures.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/data/sources/auth_source.dart';
import 'package:clean_feature_first/features/auth/domain/entities/user.dart';
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthPort)
class DefaultAuthRepository implements AuthPort {
  final AuthSource _source;

  // Wrong: arch_member_forbidden
  // Message: Forbidden member detected: Violates rule for data.repository.
  //
  // Remove or modify the member to comply with architectural rules.
  const DefaultAuthRepository(this._source);

  @override
  FutureEither<User> login(String username, String password) async {

    try {
      final model = await _source.getUser(username);
      return Right(model.toEntity());
    } on ServerException {
      return const Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<void> logout() {
    throw UnimplementedError();
  }
}
