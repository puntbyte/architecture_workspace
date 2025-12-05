// lib/features/auth/domain/ports/auth_port.violations.dart

import 'package:clean_feature_first/core/port/port.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/domain/entities/user.dart';

// LINT: [1] arch_dep_component
// REASON: Domain layer cannot import from the Data layer.
import 'package:clean_feature_first/features/auth/data/models/user_model.dart'; //! <-- LINT WARNING

// LINT: [2] arch_dep_external
// REASON: Domain must be platform agnostic (no UI types).
import 'package:flutter/material.dart'; //! <-- LINT WARNING

// LINT: [3] arch_naming_pattern // correct
// REASON: Name must match the pattern `{{name}}Port` (e.g., AuthPort).
abstract interface class AuthContract implements Port { //! <-- LINT WARNING
  // REASON: Return type must be `FutureEither<T>`, not raw `Future<T>`.

  // Warning: arch_safety_return_strict
  // Message: Invalid Return Type: "Future<User>" is not allowed.
  //
  // Return one of the allowed types: result.wrapper.

  // Warning: arch_safety_return_forbidden
  // Message: Invalid Return Type: "Future<User>" is forbidden. Use 'result.wrapper' instead.
  //
  // Change the return type to a permitted type.
  Future<User> login(String username); //! <-- LINT WARNING

  // REASON: Cannot return a Data Model (DTO) from a Domain Port. Use Entities.

  // Warning: arch_safety_return_strict
  // Message: Invalid Return Type: "Future<Either<Failure, UserModel>>" is not allowed.
  //
  // Return one of the allowed types: result.wrapper.

  // Warning: arch_safety_return_forbidden
  // Message: Invalid Return Type: "Future<Either<Failure, UserModel>>" is forbidden. Use 'result.wrapper' instead.
  //
  // Change the return type to a permitted type.

  // Warning: arch_dep_component
  // Message: Dependency Violation: Port cannot depend on Model. Allowed dependencies: Core, Shared, Config....
  //
  // Remove the dependency to maintain architectural boundaries.
  FutureEither<UserModel> unsafeReturn(); //! <-- LINT WARNING
}



// LINT: [3] arch_naming_pattern // correct
// REASON: Name must match the pattern `{{name}}Port` (e.g., AuthPort).
abstract interface class AuthContract2 implements Port { //! <-- LINT WARNING
  // REASON: Return type must be `FutureEither<T>`, not raw `Future<T>`.

  // Warning: arch_safety_return_forbidden
  // Message: Invalid Return Type: "Future<User>" is forbidden. Use 'result.wrapper' instead.
  //
  // Change the return type to a permitted type.
  Future<User> login(String username); //! <-- LINT WARNING

  // REASON: Cannot return a Data Model (DTO) from a Domain Port. Use Entities.

  // Warning: arch_safety_return_forbidden
  // Message: Invalid Return Type: "Future<Either<Failure, UserModel>>" is forbidden. Use 'result.wrapper' instead.
  //
  // Change the return type to a permitted type.

  // Warning: arch_dep_component
  // Message: Dependency Violation: Port cannot depend on Model. Allowed dependencies: Core, Shared, Config....
  //
  // Remove the dependency to maintain architectural boundaries.
  // My Review:
  FutureEither<UserModel> unsafeReturn(); //! <-- LINT WARNING

  // LINT: [9] enforce_type_safety
  // REASON: Parameter named 'id' must be of type `IntId`, not `int`.
  FutureEither<User> getUser(int id); //! <-- LINT WARNING
}

// LINT: [8] arch_type_missing_base
// REASON: Ports must implement/extend the base `Port` interface defined in Core.
abstract interface class UncontractedAuthPort { //! <-- LINT WARNING
  void doSomething();

  // LINT: [6] arch_dep_component
  // REASON: Cannot accept a Data Model as a parameter. Use Entities.
  FutureEither<void> unsafeParam(UserModel user); //! <-- LINT WARNING

  // LINT: [7] missing_use_case
  // REASON: No corresponding UseCase file found for method `revokeToken`.
  // (Expected: lib/features/auth/domain/usecases/revoke_token.dart)
  FutureEither<void> revokeToken(); //! <-- LINT WARNING (Quick Fix available)
}

abstract interface class TypeSafetyViolationsPort implements Port {
  // REASON: Return type must be `FutureEither<T>`, not raw `Future<T>`.
  Future<User> login(String username); //! <-- LINT WARNING

  // LINT: [9] enforce_type_safety
  // REASON: Parameter named 'id' must be of type `IntId`, not `int`.
  FutureEither<User> getUser(int id); //! <-- LINT WARNING

  // LINT: [10] enforce_type_safety
  // REASON: Parameter named 'id' must be of type `StringId`, not `String`.
  FutureEither<void> deleteUser(String id); //! <-- LINT WARNING
}

abstract interface class PurityViolationsPort implements Port {
  // LINT: [11] disallow_flutter_in_domain
  // REASON: Cannot use Flutter types (Color) in the Domain layer.
  // ignore: missing_use_case
  Color getUserColor(); //! <-- LINT WARNING
}

// LINT: [12] arch_naming_grammar
// REASON: Grammar violation. Ports should be Noun Phrases (e.g., AuthPort).
// 'FetchingUserPort' implies an action (Verb), which is reserved for UseCases.
abstract interface class FetchingUserPort implements Port { //! <-- LINT WARNING
  FutureEither<User> fetch();
}
