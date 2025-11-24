// lib/features/auth/data/model/user_model.dart

import 'package:example/features/auth/domain/entities/user.dart';

// CORRECT: Naming {{name}}Model, Extends Entity.
class UserModel extends User {
  const UserModel({required super.id, required super.username});

  // CORRECT: Has required mapping method.
  User toEntity() => this;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'], username: json['name']);
  }
}

