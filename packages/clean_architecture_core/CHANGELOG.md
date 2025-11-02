## 1.0.0

*   **Initial stable release of `clean_architecture_core`.**
*   **BREAKING:** The core base classes (`Repository`, `UseCase`, `Failure`, `FutureEither`) have been extracted from `clean_architecture_kit` (v2.0.0) into this dedicated package.

### Features

*   Provides a `Repository` abstract interface as a base for all repository contracts.
*   Provides `UseCase`, `UnaryUseCase`, and `NullaryUseCase` abstract interfaces for business logic interactors.
*   Provides a simple `Failure` abstract interface to represent failure cases.
*   Includes a `FutureEither<T>` typedef for convenient asynchronous operations that return a result or a failure, designed for use with the `fpdart` package.

### Rationale

This decoupling allows the `clean_architecture_kit` linter to be a pure static analysis tool. This `core` package provides an optional, lightweight, and zero-dependency (other than `fpdart`) foundation that enables the linter to work out-of-the-box.