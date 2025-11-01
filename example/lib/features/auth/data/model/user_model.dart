import '../../domain/entities/user.dart';

// This is a data Model (or DTO). It represents the data structure from the API.
// It is NOT a pure domain Entity.
class UserModel extends User {
  final String id;
  final String name;

  const UserModel({required this.id, required this.name}) : super(id: '', name: '');

  // The mapping logic that converts the "impure" Model to a "pure" Entity.
  User toEntity() => User(id: id, name: name);
}
