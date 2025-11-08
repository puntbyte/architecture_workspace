// example/lib/features/auth/domain/usecases/save_user.dart

import 'package:example/core/usecase/usecase.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
import 'package:injectable/injectable.dart';

typedef _SaveUserParams = ({String name, String password});

@Injectable()
final class SaveUser implements UnaryUsecase<void, _SaveUserParams> {
  final AuthRepository repository;

  const SaveUser(this.repository);

  @override
  FutureEither<void> call(_SaveUserParams params) {
    return repository.saveUser(name: params.name, password: params.password);
  }
}
