// example/lib/features/auth/data/models/user_model.violations.dart

import 'package:example/features/auth/domain/entities/user.dart';

// VIOLATION: enforce_model_inherits_entity (does not implement an Entity)
class OrphanUserModel { // <-- LINT WARNING HERE
  User toEntity() => User(id: '1', name: '');
}

// VIOLATION: enforce_model_to_entity_mapping (missing toEntity() method)
class IncompleteUserModel extends User { // <-- LINT WARNING HERE
  const IncompleteUserModel({required super.id, required super.name});
}

// VIOLATION: enforce_naming_conventions (name 'UserDTO' does not match '{{name}}Model')
class UserDTO extends User { // <-- LINT WARNING HERE
  const UserDTO({required super.id, required super.name});
  User toEntity() => User(id: id, name: name);
}
