# Architecture Workspace

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A modular ecosystem for enforcing architectural standards in Dart & Flutter projects. This monorepo 
separates the **Linting Engine** from the **Architectural Implementations**, allowing for flexible, 
configuration-driven development.

This workspace is managed by [Melos](https://melos.invertase.dev).

## 📦 Packages

| Package                                                     | Role            | Description                                                                                                                                                   |
|:------------------------------------------------------------|:----------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **[`architecture_lints`](./packages/architecture_lints)**   | **The Engine**  | A completely architecture-agnostic linter. It enforces rules defined in `architecture.yaml`, handling boundaries, naming, type safety, and code generation.   |
| **[`architecture_clean`](./packages/architecture_clean)**   | **The Preset**  | A tailored implementation of Clean Architecture. Provides base classes (`UseCase`, `Entity`, `Failure`), default YAML configurations, and Mustache templates. |
| **[`clean_feature_first`](./examples/clean_feature_first)** | **The Example** | A reference Flutter application demonstrating the "Feature-First" Clean Architecture approach with live linting rules.                                        |

## 🚀 Contributing

1.  **Bootstrap:** Link all local packages.
    ```bash
    melos bootstrap
    ```

2.  **Analyze Example:** Run the linter on the example project to see rules in action.
    ```bash
    melos analyze
    ```

3.  **Watch Mode:** Develop the linter and see changes update immediately in the example.
    ```bash
    melos watch
    ```

4.  **Test:** Run unit tests across all packages.
    ```bash
    melos test
    ```