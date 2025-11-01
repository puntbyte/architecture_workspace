import 'package:example/core/usecase/usecase.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/types.dart';
import '../contracts/auth_repository.dart';
import '../entities/user.dart';

@Injectable()
final class GetCurrentUserUsecase implements NullaryUsecase<User?> {
  const GetCurrentUserUsecase(this.repository);

  final AuthRepository repository;

  @override
  FutureEither<User?> call() => repository.getCurrentUser();
}
