## 0.1.3

- **Feature:** Introduced new grammar tokens for phrase validation.
  - Added `noun.phrase`, `noun.singular.phrase`, `noun.plural.phrase`.
  - Added `verb.phrase`, `verb.present.phrase`, `verb.past.phrase`.

## 0.1.2

- **Docs:** Restructure and clarify README documentation
  - Reorganized the `README.md` for improved clarity and readability by converting descriptive 
    paragraphs into structured tables for core concepts like `modules` and `components`.
  - Separated `Definitions` and `Properties` into distinct sections with their own tables to 
    clarify configuration structure.
  - Updated the table of contents with revised numbering and links.
  - Improved and clarified descriptions for various properties, including `pattern`, `antipattern`, 
    and `grammar` tokens.
  - Refined type information in property tables for better accuracy (e.g., `List<Enum>` to 
    `Set<Enum>`).
  - Removed an obsolete `Reference` section from the table of contents.

## 0.1.1

- **Refactor:** Replace language engine with `lexicor` from `dictionaryx` and enhance grammar logic.
- **Debug:** Introduced `ArchLogger`, a new tagged logging utility, to aid in debugging complex 
  grammar and file resolution logic.
- **Docs:**
  - Restructured the `README.md` for better readability by converting descriptive sections into 
    clear, tabular formats.
  - Reorganized the table of contents and section numbering for a more logical flow.
  - Clarified and expanded descriptions for `modules`, `components`, `actions`, and other core 
    concepts with detailed tables.

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