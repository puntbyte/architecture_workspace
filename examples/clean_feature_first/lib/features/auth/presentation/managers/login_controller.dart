// LINT: [Dep] arch_dep_external
// REASON: Business Logic should be pure Dart (or basic foundation).
// Importing material.dart couples logic to specific UI toolkit.
import 'package:flutter/material.dart'; //! <-- WARNING

// LINT: [Naming] arch_naming_pattern
// REASON: Name must match '{{name}}Bloc' or '{{name}}Cubit'.
// LINT: [Inheritance] arch_type_missing_base
// REASON: Must extend Bloc or Cubit.
class LoginController extends ChangeNotifier {
  //! <-- WARNING (Naming & Inheritance)

  void login() {
    // Logic here...
  }
}
