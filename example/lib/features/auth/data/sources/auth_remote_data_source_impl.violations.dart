// example/lib/features/auth/data/sources/auth_remote_data_source_impl.violations.dart
import 'package:example/features/auth/domain/entities/entities.violations.dart';
import 'package:example/features/auth/domain/entities/user_entity.dart';
import 'package:example/features/auth/data/models/user_model.dart';
import 'package:example/features/auth/data/sources/auth_remote_data_source.dart';

// --- Example 1: Naming Convention Violation ---
// This class name violates the configured 'Default{{name}}DataSource' format.

// VIOLATION: enforce_naming_conventions
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource { // <-- LINT WARNING HERE
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


// --- Example 2: Domain Purity Violations in Implementation ---
// This class demonstrates violations within the body and fields of an implementation.

class PurityViolationsDataSourceImpl implements AuthRemoteDataSource {

  // VIOLATION: disallow_entity_in_data_source
  // A field within a data source should not be a domain Entity.
  final UserEntity? lastUser; // <-- LINT WARNING HERE

  const PurityViolationsDataSourceImpl({this.lastUser});

  @override
  Future<UserModel> getUser(int id) async {
    // VIOLATION: disallow_entity_in_data_source
    // A local variable within a data source should not be a domain Entity.
    final UserEntity entity = UserEntity(id: '1', name: 'test'); // <-- LINT WARNING HERE
    print(entity);

    return UserModel(id: id.toString(), name: 'Test User');
  }

  @override
  Future<void> saveUserFromModel(UserModel user) {
    throw UnimplementedError();
  }
}

// VIOLATION: disallow_entity_in_data_source
// A top-level variable in a data source file cannot be a domain Entity.
final UserEntity topLevelEntityInDataSource = UserEntity(id: 'global', name: 'global'); // <-- LINT WARNING HERE