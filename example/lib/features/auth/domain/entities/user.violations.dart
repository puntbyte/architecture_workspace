// VIOLATION: disallow_flutter_imports_in_domain
import 'package:flutter/material.dart';

// This entity uses a Flutter type, which is not allowed in the domain layer.
class InvalidUserEntity {
  final String id;
  final Color profileColor; // <-- LINT WARNING HERE

  const InvalidUserEntity({required this.id, required this.profileColor});
}
