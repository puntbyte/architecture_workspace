## 0.1.0

🎉 **Initial Beta Release**

The first release of **Architecture Lints**, a configuration-driven, architecture-agnostic static 
analysis engine.

### 🌟 Core Features
*   **Architecture Agnostic:** Supports Clean Architecture, MVVM, MVC, Layer-First, Feature-First, 
or any custom structure defined in `architecture.yaml`.
*   **Smart Resolution Engine:**
    * **`FileResolver`**: Identifies architectural components based on file paths.
    * **`ComponentRefiner`**: Disambiguates co-located files (e.g., Interface vs. Implementation) 
       using AST analysis (Inheritance, Naming Patterns, and Structure).
*   **Configuration DSL:**
    * **Definitions:** Define reusable types, imports, and rewrites.
    * **Components:** Define layers with `mode` (namespace/file/part), `kind` (class/enum), and 
        `modifier` (abstract/sealed).
    *   **Expressions:** Support for Dart-like syntax (`${source.name.pascalCase}`) in configurations.

### 🛡️ Lint Rules
*   **Boundaries:**
    *   `arch_dep_component`: Enforces strict dependency rules between layers (e.g., Domain cannot
        import UI).
    *   Support for `allowed` (whitelist) and `forbidden` (blacklist) imports.
*   **Naming:**
    *   `arch_naming_pattern`: Enforces regex patterns (e.g., `${name}UseCase`).
    *   `arch_naming_antipattern`: Bans specific naming conventions.
    *   **NLP Support:** Basic grammar checks (`${noun}`, `${verb}`) for semantic naming.
*   **Type Safety:**
    *   `arch_safety_return_strict`: Enforces return types (e.g., `FutureEither<T>`).
    *   `arch_safety_param_strict`: Enforces parameter types (e.g., `UserId` instead of `int`).
    *   Supports deep generic unwrapping and type aliases.
*   **Structure & Consistency:**
    *   `arch_structure_modifier`: Enforces Dart keywords (e.g., Interfaces must be `abstract`).
    *   `arch_parity_missing`: Detects missing companion files (e.g., Port missing its UseCase).
*   **Exceptions:**
    *   `arch_exception_forbidden`: Bans specific operations (throw/catch) per layer.
*   **Usage:**
    *   `arch_usage_global_access`: Detects and bans Service Locator usage in pure layers.

### ⚡ Automation (Actions)
*   **Code Generation:** Integrated Action Engine to generate code when rules are violated.
*   **Templates:** Support for standard **Mustache** templates.
*   **Variable Resolver:** Resolves context variables, imports, and logic for templates dynamically.
*   **Debug Mode:** `debug_component_identity` rule to visualize how the engine parses your code.