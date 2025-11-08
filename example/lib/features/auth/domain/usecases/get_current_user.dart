// lib/features/auth/domain/usecases/get_current_user.dart

import 'package:example/core/usecase/usecase.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
import 'package:example/features/auth/domain/entities/user.dart';
import 'package:injectable/injectable.dart';

// COMPLIANT: Name `GetCurrentUser` matches `{{name}}`, implements base Usecase.
@Injectable()
class GetCurrentUser implements NullaryUsecase<User?> {
  final AuthRepository _repository;
  const GetCurrentUser(this._repository);

  @override
  FutureEither<User?> call() => _repository.getCurrentUser();
}