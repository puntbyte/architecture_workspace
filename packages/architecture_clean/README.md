# Architecture Clean

[![pub package](https://img.shields.io/pub/v/architecture_clean.svg)](https://pub.dev/packages/architecture_clean)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

The official **Clean Architecture** preset for the [`architecture_lints`](https://pub.dev/packages/architecture_lints) ecosystem.

This package provides the **Base Classes**, **Linting Rules**, and **Code Generation Templates** needed to implement a strict, scalable Clean Architecture in Flutter.

## 🧩 What's Inside?

This is not just a library; it is an **Architectural Blueprint**.

1.  **Core Primitives:** Base classes for `UseCase`, `Entity`, `Failure`, and `Either` types.
2.  **Lint Presets:** Pre-configured `architecture.yaml` files that enforce strict boundaries (e.g., "Domain cannot import UI").
3.  **Smart Generators:** Mustache templates that integrate with the linter to auto-generate UseCases, Repositories, and Mappers.

---

## 📦 Installation

This package works in tandem with `architecture_lints`.

**1. Add Dependencies (`pubspec.yaml`)**

```yaml
dependencies:
  # The base classes (UseCase, Entity, etc.)
  architecture_clean: ^0.1.0
  # Functional programming types (Either, Option)
  fpdart: ^1.0.0 

dev_dependencies:
  # The linting engine
  custom_lint: ^0.6.4
  architecture_lints: ^1.0.0
```

**2. Enable the Linter (`analysis_options.yaml`)**

```yaml
analyzer:
  plugins:
    - custom_lint
```

**3. Configure the Project (`architecture.yaml`)**

Create an `architecture.yaml` file in your root directory and import the preset.

```yaml
# Import the standard configuration
include: package:architecture_clean/presets/feature_first.yaml

# (Optional) Override specific settings
architecture:
  style: clean
  mode: feature_first

# (Optional) Define your specific modules if different from default
modules:
  feature:
    path: 'lib/features/${name}'
```

---

## 🏛️ The Architecture

This preset enforces a strict separation of concerns based on the **Dependency Rule**: *Source code dependencies must point only inward, toward higher-level policies.*

### The Layers (Inner to Outer)

| Layer | Component | Base Class (Provided) | Responsibility |
| :--- | :--- | :--- | :--- |
| **Domain** | **Entity** | `Entity` | Pure business objects. No JSON, no Flutter. |
| **Domain** | **Port** | `Repository` (Interface) | Defines the contract for data access. |
| **Domain** | **UseCase** | `UseCase<T, P>` | Encapsulates a single business action. |
| **Data** | **Model** | - | Data Transfer Objects (DTOs). Extends Entity. |
| **Data** | **Source** | - | API/DB access. Returns raw data. |
| **Data** | **Repository** | `Repository` (Impl) | Coordinates Sources to fulfill Domain Ports. |
| **UI** | **Manager** | `Bloc` / `Cubit` | Manages state. Depends on UseCases. |

---

## ⚡ Available Quick Fixes

When you violate a rule, `architecture_lints` uses the templates from this package to fix it for you.

### 1. `create_usecase`
*   **Trigger:** Defined a method in a Repository Interface (Port) but the UseCase doesn't exist.
*   **Action:** Generates a fully typed UseCase class implementing `UnaryUseCase` or `NullaryUseCase`.

### 2. `create_to_entity`
*   **Trigger:** A Data Model exists but is missing the `toEntity()` mapper.
*   **Action:** Injects the mapper method mapping fields correctly.

### 3. `create_implementation`
*   **Trigger:** An Interface exists (e.g. `AuthSource`) but the Implementation (`AuthSourceImpl`) is missing.
*   **Action:** Scaffolds the implementation class.

---

## 🛠️ Usage Guide

### 1. Define an Entity
Start in the Domain layer.

```dart
// lib/features/user/domain/entities/user.dart
import 'package:architecture_clean/src/domain/entity.dart';

class User extends Entity {
  final String id;
  final String name;
  
  const User({required this.id, required this.name});
  
  @override
  List<Object?> get props => [id, name];
}
```

### 2. Define a Port (Interface)
Define what you need.

```dart
// lib/features/user/domain/ports/user_repository.dart
import 'package:architecture_clean/src/domain/repository.dart';
import 'package:architecture_clean/src/utils/result.dart';

abstract interface class UserRepository {
  // The linter will flag this method and offer to generate 'GetUserUseCase'
  FutureEither<User> getUser(String id);
}
```

### 3. Generate the UseCase
Click the Quick Fix on `getUser`. The linter generates:

```dart
// lib/features/user/domain/usecases/get_user.dart
import 'package:architecture_clean/src/domain/usecase.dart';
import 'package:injectable/injectable.dart';

@Injectable()
class GetUserUseCase implements UnaryUseCase<User, String> {
  final UserRepository _repository;
  const GetUserUseCase(this._repository);

  @override
  FutureEither<User> call(String params) {
    return _repository.getUser(params);
  }
}
```

---

## 📂 Presets Reference

The package comes with standard configurations available via `include`:

*   **`package:architecture_clean/presets/feature_first.yaml`** (Recommended)
    *   Groups code by Feature (`features/auth/domain`, `features/auth/presentation`).
*   **`package:architecture_clean/presets/layer_first.yaml`**
    *   Groups code by Layer (`domain/auth`, `presentation/auth`).
*   **`package:architecture_clean/presets/base.yaml`**
    *   Contains only the Definition mappings (Types) without directory enforcement. Use this if you have a custom folder structure but want the Type Safety rules.