// example/lib/features/auth/data/repositories/default_auth_repository.violations.dart

import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/data/sources/auth_remote_data_source.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
import 'package:example/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

// VIOLATION: enforce_repository_implementation_contract (does not implement AuthRepository)
class UnrelatedRepository {}

class BadDependencyRepository implements AuthRepository {
  // VIOLATION: enforce_abstract_data_source_dependency (depends on concrete implementation)
  final DefaultAuthRemoteDataSource _dataSource; // <-- LINT WARNING HERE
  const BadDependencyRepository(this._dataSource);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class BadErrorHandlingRepository implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  const BadErrorHandlingRepository(this._dataSource);

  @override
  FutureEither<User> getUser(int id) async {
    // VIOLATION: enforce_try_catch_in_repository (call to data source is not in a try-catch)
    final userModel = await _dataSource.getUser(id); // <-- LINT WARNING HERE
    return Right(userModel.toEntity());
  }

  @override
  FutureEither<void> saveUser({required String name}) async {
    try {
      await Future.value();
    } catch (e) {
      // VIOLATION: disallow_throwing_from_repository (must not re-throw)
      throw Exception('Failed'); // <-- LINT WARNING HERE
    }
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class BadInstantiationRepository implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  // VIOLATION: disallow_dependency_instantiation (creates its own dependency)
  BadInstantiationRepository() : _dataSource = DefaultAuthRemoteDataSource(); // <-- LINT WARNING HERE

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}