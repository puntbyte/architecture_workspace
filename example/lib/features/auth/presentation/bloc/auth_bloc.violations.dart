import 'package:bloc/bloc.dart';

import '../../domain/contracts/auth_repository.dart';
import 'auth_bloc.dart';

// VIOLATION: presentation_layer_purity
// This BLoC incorrectly depends on the entire AuthRepository.
class AuthBlocViolations extends Bloc<AuthEvent, AuthState> {
  // It should depend on a specific UseCase instead.
  final AuthRepository _repository;

  AuthBlocViolations(
    this._repository, // <-- LINT WARNING HERE
  ) : super(AuthInitial());
}
