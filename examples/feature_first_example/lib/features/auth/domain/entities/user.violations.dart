// lib/features/auth/domain/entities/user.violations.dart

import 'package:example/core/entity/entity.dart';
// LINT: disallow_flutter_in_domain
// Reason: Domain must be platform agnostic.
import 'package:flutter/material.dart'; // <-- LINT WARNING HERE

// LINT: enforce_naming_conventions
// Reason: Entities should not have 'Entity' suffix (antipattern).
class UserEntity implements Entity { // <-- LINT WARNING HERE
  // LINT: disallow_flutter_in_domain
  // Reason: Using UI types in domain.
  final Color favoriteColor; // <-- LINT WARNING HERE

  const UserEntity({required this.favoriteColor});
}

// LINT: enforce_entity_contract
// Reason: Must extend the base `Entity` class.
class UncontractedUser { // <-- LINT WARNING HERE
  const UncontractedUser();
}
