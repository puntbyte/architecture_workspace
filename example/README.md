# Architecture Kit - Example Project

This Flutter project demonstrates all the features of the `architecture_kit` package.

## 1. How to See the Lints

The project contains several `*.violations.dart` files. Open any of them to see errors and warnings from the linter.

- **`lib/features/auth/domain/entities/user.violations.dart`**: Shows `disallow_flutter_imports_in_domain`.
- **`lib/features/auth/domain/repositories/auth_repository.violations.dart`**: Shows `enforce_layer_independence`, `enforce_repository_inheritance`, `enforce_custom_return_type`, and `enforce_naming_conventions`.
- **`lib/features/auth/data/repositories/auth_repository_impl.violations.dart`**: Shows `enforce_abstract_data_source_dependency`.
- **And more...**

## 2. How to Use the Quick Fix (Code Generation)

The package will detect repository methods that are missing a use case and offer to generate them for you.

1.  Open `lib/features/auth/domain/repositories/auth_repository.dart`.
2.  You will see an **informational lint** (a blue squiggly line) under the method names `getUser` and `saveUser`, because their use cases do not exist yet.
3.  Place your cursor on a method name like `getUser`.
4.  Trigger the "quick fix" lightbulb in your IDE (usually `Ctrl + .` or `Cmd + .`).
5.  Select **"Create use case for `getUser`"**.
6.  A new file, `lib/features/auth/domain/usecases/get_user_usecase.dart`, will be instantly created with all the correct boilerplate.