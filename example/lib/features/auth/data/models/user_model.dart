// example/lib/features/auth/data/model/user_model.dart
import 'package:example/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
  });

  User toEntity() => User(id: id, name: name);
}
