// lib/features/auth/domain/entities/user.dart

import 'package:example/core/entity/entity.dart';

// Compliant: Name `User` matches `{{name}}` pattern, and it extends `Entity`.
class User extends Entity {
  final String id;
  final String name;

  const User({required this.id, required this.name});
}
