// example/lib/features/auth/domain/entities/entities.violations.dart

import 'package:example/core/entity/entity.dart';
// VIOLATION: enforce_layer_independence (domain cannot import from data/presentation)
import 'package:example/features/auth/data/models/user_model.dart'; // <-- LINT WARNING HERE
// VIOLATION: disallow_flutter_in_domain (disallows Flutter imports)
import 'package:flutter/material.dart'; // <-- LINT WARNING HERE

// KNOWN ISSUE: enforce_naming_conventions will flag the following when the naming convention
// is different from `{{name}}` pattern, in the current example config this is not a violation.
// VIOLATION: enforce_naming_conventions (name 'UserObject' does not match the '{{name}}' template)
class UserObject extends Entity { // <-- LINT WARNING HERE (placeholder)
  final String id;
  const UserObject({required this.id});
}

// KNOWN ISSUE: enforce_naming_conventions does not work when there is naming convention ambiguity
// (when there is more than one similar naming_convention pattern). In addition when countering a
// forbidden naming convention pattern, the lint flags but does not show the correct error message.
// VIOLATION: enforce_naming_conventions (name uses forbidden 'Entity' suffix)
class UserEntity extends Entity { // <-- LINT WARNING HERE
  final String id;
  const UserEntity({required this.id});
}

// VIOLATION: enforce_entity_contract (does not extend the base `Entity` class)
class User { // <-- LINT WARNING HERE
  final String id;
  final String name;
  const User({required this.id, required this.name});
}

class FlutterUser extends Entity {
  final String id;
  // VIOLATION: disallow_flutter_in_domain (uses forbidden Flutter type 'Color')
  final Color profileColor; // <-- LINT WARNING HERE

  const FlutterUser({required this.id, required this.profileColor});
}

// VIOLATION: enforce_file_and_folder_location (A 'Model' was found in an 'entities' directory)
class SomeDataModel extends Entity { // <-- LINT WARNING HERE
  final String id;
  const SomeDataModel({required this.id});
}
