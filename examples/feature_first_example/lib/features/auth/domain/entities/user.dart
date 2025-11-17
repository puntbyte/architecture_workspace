// example/lib/features/auth/domain/entities/user.dart

import 'package:example/core/entity/entity.dart';

class User extends Entity {
  final String id;
  final String name;

  const User({required this.id, required this.name});
}
