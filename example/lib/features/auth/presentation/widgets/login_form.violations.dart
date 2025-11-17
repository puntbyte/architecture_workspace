// example/lib/features/auth/presentation/widgets/login_form.violations.dart

import 'package:example/features/auth/domain/usecases/get_user.dart';
import 'package:flutter/material.dart';

class LoginFormViolations extends StatelessWidget {
  // VIOLATION: disallow_use_case_in_widget (widget depends directly on a use case)
  final GetUser _getUser; // <-- LINT WARNING HERE

  const LoginFormViolations({super.key, required GetUser getUser}) : _getUser = getUser;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // VIOLATION: disallow_use_case_in_widget (widget invokes a use case directly)
        _getUser.call(123); // <-- LINT WARNING HERE
      },
      child: const Text('Login'),
    );
  }
}