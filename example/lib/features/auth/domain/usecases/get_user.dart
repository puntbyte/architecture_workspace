import 'package:example/core/usecase/usecase.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
import 'package:example/features/auth/domain/entities/user.dart';

final class GetUser implements UnaryUsecase<User, int> {
  const GetUser(this.repository);

  final AuthRepository repository;

  @override
  FutureEither<User> call(int id) => repository.getUser(id);
}
