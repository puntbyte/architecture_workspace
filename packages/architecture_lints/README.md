# Architecture Lints 🏗️

A **configuration-driven**, **architecture-agnostic** linting engine for Dart and Flutter that 
transforms your architectural vision into enforceable code standards.

Unlike standard linters that enforce hardcoded opinions (e.g., "Always extend Bloc"), `architecture_lints` reads a **Policy Definition** from an `architecture.yaml` file in your project root. This allows you to define your **own** architectural rules, layers, and naming conventions.

It is the core engine powering packages like `architecture_clean`, but it can be used standalone to enforce any architectural style (MVVM, MVC, DDD, Layer-First, Feature-First).

---

## 📦 Installation

Add the package to your `dev_dependencies`:

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.6.4
  architecture_lints: ^1.0.0
```

Enable the plugin in `analysis_options.yaml`:

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
```

Create an `architecture.yaml` file in your project root (see Configuration below).

---

## 📋 Available Lint Rules

These rules are generic but become specific based on your configuration.

| Error Code                      | Category    | Trigger Logic                                                                                    |
|:--------------------------------|:------------|:-------------------------------------------------------------------------------------------------|
| **`arch_naming_pattern`**       | Naming      | Class name does not match the configured `pattern` (e.g., must end in `UseCase`).                |
| **`arch_naming_antipattern`**   | Naming      | Class name uses a forbidden term defined in `antipattern` (e.g., `Manager` in a `Utils` folder). |
| **`arch_structure_kind`**       | Structure   | Component is the wrong Dart kind (e.g., found `enum`, config required `class`).                  |
| **`arch_structure_modifier`**   | Structure   | Component is missing a required modifier (e.g., Interface must be `abstract`).                   |
| **`arch_dep_component`**        | Boundaries  | Layer A imports Layer B, but it is forbidden by the `dependencies` policy.                       |
| **`arch_parity_missing`**       | Consistency | A required companion file is missing (e.g., every `Port` must have a `UseCase`).                 |
| **`arch_safety_return_strict`** | Type Safety | Method returns a raw type (e.g., `Future`) instead of a required wrapper (e.g., `FutureEither`). |
| **`arch_safety_param_strict`**  | Type Safety | Method parameter uses a primitive (e.g., `int`) instead of a ValueObject (e.g., `UserId`).       |
| **`arch_exception_forbidden`**  | Exceptions  | Layer performs a forbidden operation (e.g., `throw` in UI, or `catch` in Domain).                |
| **`arch_usage_global_access`**  | Usage       | Direct access to global service locators (e.g., `GetIt.I`) is detected where banned.             |
| **`arch_usage_instantiation`**  | Usage       | Direct instantiation of a dependency (`new Repo()`) instead of using injection.                  |
| **`arch_annot_missing`**        | Annotations | Class is missing required metadata (e.g., `@Injectable`).                                        |
| **`arch_annot_forbidden`**      | Annotations | Usage of banned annotations (e.g., `@JsonSerializable` in Domain layer).                         |

---

## ⚙️ Configuration Manual (`architecture.yaml`)

This file acts as the **Domain Specific Language (DSL)** for your architecture.

### 📚 Table of Contents

1.  [**Concepts & Philosophies**](#1-concepts--philosophies)
2.  [**Core Declarations**](#2-core-declarations-the-configurations)
3.  [**Auxiliary Declarations**](#3-auxiliary)
4.  [**Policies (The Rules)**](#4-policies-enforcing-behavior)
5.  [**Automation (Code Generation)**](#5-automation-actions--templates)
6.  [**Reference: Available Options**](#6-reference-available-options)

---

## [1] 💡 Concepts & Philosophies

To effectively lint a large project, we must understand its structure on two axes:

### **Modules (Horizontal Slicing)**
Modules represent the **Features** or high-level groupings of your application.
*   *Example:* `Auth`, `Cart`, `Profile`, `Core`.
*   A module usually contains multiple layers.

### **Components (Vertical Slicing)**
Components represent the **Layers** or technical roles within a module.
*   *Example:* `Entity`, `Repository`, `UseCase`, `Widget`.
*   A component is defined by what it *is* (Structure) and where it *lives* (Path).

The Linter combines these to identify a file:
> `lib/features/auth/domain/usecases/login.dart`
>
> *   **Module:** `auth` (Derived from `features/${name}`)
> *   **Component:** `domain.usecase` (Derived from path `domain/usecases`)

---

## [2] 🎯 Core Declarations (The Configurations) 

The `architecture.yaml` file drives everything.

### [2.1] Modules (`modules`)
Defines how to parse high-level folders.

```yaml
modules:
  # Dynamic Module: Matches any folder inside 'features/'
  # The '${name}' placeholder captures the module name (e.g., 'auth').
  feature:
    path: 'features/{{name}}'
    default: true # Fallback if no other module matches

  # Static Modules: Exact path matches
  core: 'core'
  shared: 'shared'
```

### [2.2] Components (`components`)
Defines the taxonomy of your architecture. Supports hierarchy to share configuration (children 
inherit `path` prefixes).

**Key Properties:**
*   **`mode`**: Critical for resolution.
    *   `namespace`: A folder/layer container. Cannot match a file.
    *   `file`: A specific code unit (e.g., a class file).
    *   `part`: A symbol defined *inside* a file (e.g., an Event class inside a Bloc file).
*   **`kind`**: The Dart element type (`class`, `enum`, `mixin`, `extension`, `typedef`).
*   **`modifier`**: Dart keywords (`abstract`, `sealed`, `interface`).
*   **`pattern`**: Naming convention regex.
    *   `${name}`: The core name (PascalCase).
    *   `${affix}`: Wildcard match.

```yaml
components:
  # Parent Component (Namespace)
  .domain:
    path: 'domain'
    mode: namespace

    # Child Component (Concrete File)
    .port:
      path: 'ports'       # Full path becomes 'domain/ports'
      mode: file
      kind: class
      modifier: [ abstract, interface ] # Must be 'abstract interface class'
      pattern: '{{name}}Port'            # e.g. AuthPort
```

## [3] 🧩 Auxiliary Declarations 

### [3.1] Types (`types`)
Maps abstract concepts (like "Result Wrapper") to concrete Dart types. This decouples your rules 
from specific class names.

```yaml
definitions:
  # Define a type for Type Safety checks
  result_wrapper:
    types: ['FutureEither', 'Either'] # Matches these class names
    imports: ['package:core/utils/types.dart'] # Checks if this is imported
    # Optional: If code uses 'package:fpdart/src/...', rewrite it to public API
    rewrites: ['package:fpdart/src/either.dart'] 
```

### [3.2] Vocabularies (`vocabularies`)
The linter uses Natural Language Processing (NLP) to check if class names make grammatical sense 
(e.g., "UseCases must be Verb-Noun"). You can extend the dictionary with domain-specific terms.

```yaml
vocabularies:
  nouns: ['auth', 'todo', 'kyc']
  verbs: ['upsert', 'rebase']
```

---

## [4] 📜 Policies (Enforcing Behavior) 

Policies define what is required, allowed, or forbidden.

### [4.1] Dependencies (`dependencies`)
**Purpose:** Enforce the Dependency Rule (Architecture Boundaries).
**Logic:** Can `Module A` import `Module B`? Can `Layer X` import `Layer Y`?

```yaml
dependencies:
  - on: domain
    # Whitelist approach: Domain can ONLY import these
    allowed: [ 'domain', 'core' ]
    # Blacklist approach: Domain NEVER imports Flutter
    forbidden:
      import: [ 'package:flutter/**', 'dart:ui' ]
```

### [4.2] Type Safety (`type_safeties`)
**Purpose:** Enforce method signatures.
**Logic:** "Methods in this layer must return X" or "Parameters must not be Y".

```yaml
type_safeties:
  - on: domain.usecase
    allowed:
      kind: return
      definition: 'result_wrapper' # Must return FutureEither<T>
    forbidden:
      kind: return
      definition: 'future' # Cannot return raw Future<T>
```

### [4.3] Exceptions (`exceptions`)
**Purpose:** Enforce error handling flow.
**Logic:** Who is a `producer` (throws), `propagator` (rethrows), or `boundary` (catches)?

```yaml
exceptions:
  - on: data.repository
    role: boundary
    required:
      - operation: catch_return # Must have try/catch that returns (Left)
    forbidden:
      - operation: throw        # Never crash
```

### [4.4] Structure (`members` & `annotations`)
**Purpose:** Enforce internal class structure.

```yaml
members:
  - on: domain.entity
    required:
      - kind: field
        identifier: 'id' # Must have an 'id' field
    forbidden:
      - kind: setter # Immutable: No setters allowed

annotations:
  - on: domain.usecase
    required:
      - type: 'Injectable'
```

### [4.5] Relationships (`relationships`)
**Purpose:** Enforce file parity (1-to-1 mappings).
**Logic:** "For every Method in a Port, there must be a UseCase file."

```yaml
relationships:
  - on: domain.port
    kind: method
    required:
      component: domain.usecase
      action: create_usecase # Trigger this action if missing
```

---

## [5] 🤖 Automation 

The linter acts as a code generator when rules are broken.

### [5.1] Actions (`actions`)
Defines the logic for a Quick Fix. Uses a **Dart-like Expression Language** for variables.

```yaml
actions:
  create_usecase:
    description: 'Generate UseCase'
    trigger:
      error_code: 'arch_parity_missing'
      component: 'domain.port'
    
    # 1. Source: Read data from the method triggering the error
    source:
      scope: current
      element: method

    # 2. Target: Write a new file in the usecases folder
    target:
      scope: related
      component: 'domain.usecase'
    
    write:
      strategy: file
      filename: '${source.name.snakeCase}.dart' # Expression interpolation

    # 3. Variables: Prepare data for Mustache
    variables:
      # Expressions can access AST nodes and Config
      className: '${source.name.pascalCase}'
      baseClass: "config.definitionFor('usecase.base').type"
      
      # Logic: Check list size
      hasParams: 'source.parameters.length > 0'
      
    template_id: 'usecase_template'
```

### [5.2] Templates (`templates`)
Standard Mustache templates. Logic-less.

```yaml
templates:
  usecase_template:
    file: 'templates/usecase.mustache'
```

**Inside `usecase.mustache`:**
```dart
class {{className}} extends {{baseClass}} {
  {{#hasParams}}
    // Render params...
  {{/hasParams}}
}
```

---

## [6] 🔗 References (Available Options)

### Component Options
| Option         | Values                                                      | Description                                 |
|:---------------|:------------------------------------------------------------|:--------------------------------------------|
| **`mode`**     | `file`                                                      | The component is the file itself (Default). |
|                | `part`                                                      | The component is a symbol *inside* a file.  |
|                | `namespace`                                                 | The component is just a folder.             |
| **`kind`**     | `class`, `enum`, `mixin`, `extension`, `typedef`            | The Dart declaration type.                  |
| **`modifier`** | `abstract`, `sealed`, `interface`, `base`, `final`, `mixin` | Dart keywords.                              |

### Write Strategies
| Strategy      | Description                                       |
|:--------------|:--------------------------------------------------|
| **`file`**    | Creates a new file or overwrites an existing one. |
| **`inject`**  | Inserts code into an existing class body.         |
| **`replace`** | Replaces the source node entirely.                |

### Expression Engine Variables
Available in `actions` -> `variables`:

*   **`source`**: The AST Node (Class, Method, Field).
    *   `.name`: String (with properties `.pascalCase`, `.snakeCase`, etc.)
    *   `.parent`: The parent node.
    *   `.file.path`: Absolute path.
    *   `.returnType`: TypeWrapper (for methods).
    *   `.parameters`: ListWrapper (for methods).
*   **`config`**: The Architecture Config.
    *   `.definitionFor('key')`: Looks up a type definition.
    *   `.namesFor('componentId')`: Looks up naming patterns.
*   **`definitions`**: Direct map access to definitions.

---


## 🧠 Smart Resolution Logic

The linter uses a sophisticated **Component Refiner** to identify files. It doesn't just look at 
file paths; it looks at:
1.  **Path Depth**: Deeper matches are preferred.
2.  **Naming Patterns**: Does the class name match `${name}Repository`?
3.  **Inheritance**: Does the class extend `BaseRepository`?
4.  **Structure**: Is it `abstract` vs `concrete`?

This ensures that even if you have an Interface (`AuthSource`) and Implementation 
(`AuthSourceImpl`) in the *same folder*, the linter correctly applies different rules to each.

### How the Resolution Engine Works

When a file is analyzed, the **Component Refiner** calculates a score to identify it. This allows 
`AuthSource` (Interface) and `AuthSourceImpl` (Implementation) to live in the same folder but be 
treated differently.

**Scoring Criteria:**
1.  **Path Match:** Deeper directory matches get higher scores.
2.  **Mode:** `mode: file` beats `mode: part`.
3.  **Naming:** Matches configured `${name}Pattern`.
4.  **Inheritance:** Implements required base classes defined in `inheritances`.
5.  **Structure:** Matches required `kind` (class/enum) and `modifier` (abstract/concrete).

*Example:* A concrete class `AuthImpl` will fail to match a component that requires 
`modifier: abstract`, forcing the resolver to pick the Implementation component instead.