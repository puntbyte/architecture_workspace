part of 'auth_bloc.dart';

// LINT: [Structure] arch_structure_modifier
// REASON: State Base classes must be 'sealed' or 'abstract' to enforce exhaustive matching in the UI.
//import 'package:flutter/material.dart' show Icon;

class AuthState {} //! <-- WARNING

// LINT: [Naming] arch_naming_pattern
// REASON: Concrete States representing a status should use adjectives or past tense
// (e.g. AuthLoaded, AuthError), not actions.
class LoadAuth extends AuthState {} //! <-- WARNING

// LINT: [Structure] arch_structure_kind
// REASON: If your config restricts States to be Classes, Enums are forbidden.
enum AuthStatusEnum { initial, success } //! <-- WARNING

// LINT: [Safety] arch_safety_field_type (Hypothetical rule based on dependencies)
// REASON: States should hold primitive data or Domain Entities.
// They should NOT hold UI Widgets like 'Icon' or 'Text'.
class AuthError extends AuthState {
  final Icon errorIcon; //! <-- WARNING (Leaking UI into State)
  AuthError(this.errorIcon);
}