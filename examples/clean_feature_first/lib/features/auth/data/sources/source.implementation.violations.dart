// lib/features/auth/data/sources/source.implementation.violations.dart

import 'package:clean_feature_first/core/error/failures.dart';
import 'package:clean_feature_first/core/utils/service_locator.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/data/models/user_model.dart';
import 'package:clean_feature_first/features/auth/data/sources/auth_source.dart';
import 'package:fpdart/fpdart.dart';

// LINT: [1] arch_dep_external
// REASON: While this is data layer, flutter is generally discouraged in pure Dart sources
// unless it's a local source using something like SharedPreferences (depends on config).
// (Assuming config blocks it or context implies strictness).
import 'package:flutter/material.dart';

typedef Database = Object;

// LINT: [2] arch_naming_pattern
// REASON: Name must match `Default{{name}}Source` (configured pattern).
// 'AuthSourceImpl' is the standard flutter way, but this config enforces 'Default...'.
// ignore: arch_naming_grammar, arch_naming_pattern, arch_type_missing_base
class AuthSourceImpl implements AuthSource { //! <-- LINT WARNING
  // LINT: [3] arch_safety_return_forbidden
  // REASON: Implementation returns Either/Right. Sources must throw exceptions.
  FutureEither<UserModel> wrongReturnType() async { //! <-- LINT WARNING
    return Right(UserModel(id: '1', name: 'Test'));
  }

  @override
  Future<UserModel> getUser(StringId id) async {

    try {
      // LINT: [4] arch_exception_forbidden
      // REASON: Sources should act as "Producers". Catching an exception and returning a
      // Failure/null here means the Repository cannot do its job of mapping exceptions.
      throw Exception('API Error');
    } catch (e) {
      // This mimics returning "Safe" data which is an anti-pattern in Sources.
      throw ServerFailure(); // Throwing a Domain Failure in Data layer is also bad.
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    // LINT: [5] not visible
    // REASON: Dependencies (like HTTP client or DB) must be injected.
    final db = GetIt.I.get<Database>();
  }
}

// LINT: [6] arch_type_missing_base
// REASON: Concrete sources must implement an interface, not stand alone.
// ignore: arch_type_missing_base
class OrphanSource { // <-- LINT WARNING HERE
  Future<void> getData() async {}
}