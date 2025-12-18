# Clean Feature-First Example

This is a reference application demonstrating how to use `architecture_clean` and `architecture_lints` to enforce a strict **Feature-First Clean Architecture**.

## 📂 Project Structure

This project organizes code by **Feature** first, then by **Layer**.

```text
lib/
├── core/                  # Shared kernel (Failure, UseCase base, etc.)
└── features/
    └── auth/              # Feature Module
        ├── domain/        # Inner Circle (Entities, Ports, UseCases)
        ├── data/          # Outer Circle (Models, Sources, Repositories)
        └── presentation/  # UI (Pages, Managers/Blocs)
```

## 🧪 Seeing the Lints in Action

This project contains intentional "violations" to demonstrate the linter's capabilities.

1.  **Open `lib/features/auth/domain/usecases/login.dart`**:
    *   *Notice:* If you remove `implements UnaryUsecase`, the linter will warn you.
    *   *Fix:* Use the Quick Fix "Generate Functional UseCase" to regenerate the file.

2.  **Open `lib/features/auth/data/repositories/auth_repository_impl.dart`**:
    *   *Check:* Try importing a Widget. The **Boundary Rule** will flag it immediately.

3.  **Open `lib/features/auth/domain/ports/auth_port.dart`**:
    *   *Check:* Change a return type from `FutureEither<User>` to `Future<User>`. The **Type Safety Rule** will flag the raw Future as unsafe.

## 🏃‍♂️ Running the Linter

To see all architectural violations in the terminal:

```bash
# From the workspace root
melos analyze
```

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis