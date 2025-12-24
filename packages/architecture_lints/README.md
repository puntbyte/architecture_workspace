```markdown
# Architecture Lints 🏗️

A **configuration-driven**, **architecture-agnostic** linting engine for Dart and Flutter that transforms your architectural vision into enforceable code standards.

Unlike standard linters that enforce hardcoded opinions (e.g., "Always extend Bloc"), `architecture_lints` reads a **Policy Definition** from an `architecture.yaml` file in your project root. This allows you to define your **own** architectural rules, layers, and naming conventions.

It is the core engine powering packages like `architecture_clean`, but it can be used standalone to enforce any architectural style (MVVM, MVC, DDD, Layer-First, Feature-First).

---

## 📦 Installation

Add the package to your `dev_dependencies`:

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.8.0
  architecture_lints: ^0.1.0
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
| **`arch_usage_instantiation`**  | Usage       | Direct instantiation of a dependency (`new Repository()`) instead of using injection.            |
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
- *Example:* `Core`, `Shared`, `Profile`, `Auth`.
- A module usually contains multiple layers.

### **Components (Vertical Slicing)**
Components represent the **Layers** or technical roles within a module.
- *Example:* `Entity`, `Repository`, `UseCase`, `Widget`.
- A component is defined by what it *is* (Structure) and where it *lives* (Path).

The Linter combines these to identify a file:
> `lib/features/auth/domain/usecases/login.dart`
>
> - **Module:** `auth` (Derived from `features/{{name}}`)
> - **Component:** `domain.usecase` (Derived from path `domain/usecases`)

---

## [2] 🎯 Core Declarations (The Configurations)

The `architecture.yaml` file drives everything.

### [2.1] Modules (`modules`)

Defines the high-level boundaries (features or layers) of your application. The linter uses these definitions to understand which part of the codebase a file belongs to.

#### Definition
**`<module_key>`**: The unique identifier for the module. This ID is used when referencing modules 
in dependency rules
- **Type:** `String` *(YAML Map Key)*
- **Style**:
  - **Shorthand:** `<key>: '<path>'` for simple path mapping
  - **Expanded:** `<key>: { path: '<path>', default: <bool> }` for additional options

#### Properties

**[a] `path`**: The root directory for this module relative to the project root
- **Type:** `String`
- **Placeholders:**
    - `{{name}}`: Dynamic module indicator. The folder name becomes the module instance name
    - `*`: Standard glob wildcard for ignoring intermediate folders

**[b] `default`**: Whether this module is the fallback for unmatched components
- **Type:** `Boolean`
- **Default:** `false`

#### Example

```yaml
modules:
  # [Dynamic] Feature modules under features/
  # ID: 'feature', Instance: 'auth', 'payments', etc.
  feature:
    path: 'features/{{name}}'
    default: true # Unmatched components belong here

  # [Static] Core module
  # ID: 'core', Path: 'lib/core'
  core: 'core'

  # [Static] Shared module
  # ID: 'shared', Path: 'lib/shared'
  shared: 'shared'
```

### [2.2] Components (`components`)

Maps your file system structure to architectural concepts. This is the core taxonomy of your 
project.

#### Definition
**`<component_key>`**:
- **Type:** `String` *(YAML Map Key)*
- **Style**:
  - **Hierarchy**: Keys starting with `.` are children. Their ID concatenates with parent 
    (e.g., `domain` + `.port` = `domain.port`).
  - **Inheritance**: Child components automatically inherit the `path` of their parent, allowing 
    you to map nested folder structures easily.

#### Properties

**[a] `mode`**: **Critical for Resolution.** Defines what this component represents physically in 
the codebase
- **Type:** `String` *(Enumeration)*
- **Options:**
  - `file`: *(Default)* Represents a specific code unit (e.g., a class in a file). Matches based on 
    file name and content
  - `namespace`: Represents a folder or layer container. Matches directories, never specific files. 
    Use this for parent keys (e.g., `domain`)
  - `part`: Represents a symbol defined *inside* a file (e.g., an `Event` class defined within a 
    Bloc file). Use this for detailed structural checks within a file

**[b] `path`**: The directory name(s) relative to the parent component
- **Type:** `String | List<String>`
- **Behavior:** If parent has `path: domain` and child has `path: entities`, the full path is `domain/entities`

**[c] `kind`**: Enforces the specific Dart declaration type
- **Type:** `String | List<String>`
- **Options:** `class`, `enum`, `mixin`, `extension`, `typedef`

**[d] `modifier`**: Enforces specific Dart keywords on the declaration
- **Type:** `String | List<String>`
- **Options:** `abstract`, `sealed`, `interface`, `base`, `final`, `mixin` (for mixin classes)

**[e] `pattern`**: A regex-based naming convention for the class or element name
- **Type:** `String | List<String>`
- **Placeholders:**
    - `{{name}}`: Captures the core domain name in PascalCase (e.g., `GetUser`)
    - `{{affix}}`: A non-greedy wildcard matching any prefix or suffix

**[f] `antipattern`**: Forbidden naming patterns to guide users away from bad habits
- **Type:** `String | List<String>`
- **Placeholders:** Same as `pattern`

**[g] `grammar`**: Semantic naming pattern using parts of speech
- **Type:** `String | List<String>`
- **Tokens:**
    - `{{noun}}`, `{{noun.phrase}}`, `{{noun.singular}}`, `{{noun.plural}}`
    - `{{verb}}`, `{{verb.present}}`, `{{verb.past}}`, `{{verb.gerund}}`
    - `{{adjective}}`, `{{adverb}}`, etc.

#### Example

```yaml
components:
  # [Namespace] Domain Layer
  # ID: 'domain'
  # Path: 'domain'
  # Mode: 'namespace' ensures this never matches a specific file, only the folder
  .domain:
    path: 'domain'
    mode: namespace

    # [Component] Domain Port
    # ID: 'domain.port' (Concatenated)
    # Path: 'domain/ports' (Inherited + Appended)
    .port:
      path: 'ports'
      mode: file
      
      # Structural Rules: Must be 'abstract interface class'
      kind: class
      modifier: [ abstract, interface ]
      
      # Naming Rule: Must end in 'Port' (e.g. AuthPort)
      pattern: '{{name}}Port'
      antipattern: '{{name}}Interface' # Guide away from legacy naming
```

---

## [3] 🧩 Auxiliary Declarations

### [3.1] Types (`definitions`)

Maps abstract concepts (like "Result Wrapper") to concrete Dart types. This decouples your rules from specific class names.

#### Properties

**[a] `<group_key>`**: A logical grouping (e.g., `usecase`, `result`)
- **Type:** `Map<String, String | Map>`

**[a.1] `<type_key>`**: The unique identifier within the group
- **Type:** `String | Map`
- **Shorthand:** `key: 'ClassName'` inherits previous import
- **Detailed:** `key: { type: 'ClassName', import: '...' }`

**[a.1.1] `type`**: The raw Dart class name
- **Type:** `String`

**[a.1.2] `import`**: The package URI (inherits from previous entry if omitted)
- **Type:** `String`

**[a.1.3] `argument`**: Expected generic type parameters
- **Type:** `List<Map>` (recursive structure)

#### Example

```yaml
definitions:
  # Domain Types
  usecase:
    .base:
      type: 'Usecase'
      import: 'package:my_app/core/usecase.dart'
    .unary: 'UnaryUsecase' # Inherits import from .base
    
  # Result Wrappers
  result:
    .wrapper:
      .future:
        type: 'FutureEither'
        import: 'package:my_app/core/types.dart'
        argument: '*'
```

### [3.2] Vocabularies (`vocabularies`)

The linter uses Natural Language Processing (NLP) to check if class names make grammatical sense 
(e.g., "UseCases must be Verb-Noun"). You can extend the dictionary with domain-specific terms.

#### Properties

**[a] `nouns`**: Domain-specific noun terms
- **Type:** `List<String>`

**[b] `verbs`**: Domain-specific verb terms
- **Type:** `List<String>`

#### Example

```yaml
vocabularies:
  nouns: [ 'auth', 'todo', 'kyc' ]
  verbs: [ 'upsert', 'rebase', 'unfriend' ]
```

---

## [4] 📜 Policies (Enforcing Behavior)

Policies define what is required, allowed, or forbidden.

### [4.1] Dependencies (`dependencies`)

**Purpose:** Enforce the Dependency Rule (Architecture Boundaries)

**Logic:** Can `Module A` import `Module B`? Can `Layer X` import `Layer Y`?

#### Properties

**[a] `on`**: The component or layer target
- **Type:** `String | List<String>`

**[b] `allowed` | `forbidden`**: Whitelist (if defined, component may ONLY import these) or 
blacklist (component must NOT import these) approach. 
- **Type:** `Map`

**[b.1] `component`**: List of architectural components or layers to check against
- **Type:** `String | List<String>`

**[b.2] `import`**: List of URI patterns. Supports glob `**` for wildcards
- **Type:** `String | List<String>`

#### Example

```yaml
dependencies:
  # Domain is platform agnostic
  - on: domain
    forbidden:
      import: [ 'package:flutter/**', 'dart:ui' ]
      component: [ 'data', 'presentation' ]
  
  # UseCases can only see Domain
  - on: usecase
    allowed:
      component: [ 'entity', 'port' ]
```

### [4.2] Type Safety (`type_safeties`)

**Purpose:** Enforce method signatures

**Logic:** "Methods in this layer must return X" or "Parameters must not be Y"

#### Properties

**[a] `on`**: The component target
- **Type:** `String | List<String>`

**[b] `allowed` | `forbidden`**: Whitelist of permitted types OR Blacklist of prohibited types
- **Type:** `Map`

**[b.1] `kind`**: The context of the check
- **Type:** `String`
- **Options:** `'return' | 'parameter'`

**[b.2] `identifier`**: *(for parameters)* The parameter name to match
- **Type:** `String`

**[b.3] `definition`**: Reference to a key in the `definitions` config
- **Type:** `String | List<String>`

**[b.4] `type`**: Raw class name string (e.g., `'int'`, `'Future'`)
- **Type:** `String | List<String>`

**[b.5] `component`**: Reference to an architectural component
- **Type:** `String`

#### Example

```yaml
type_safeties:
  # Domain must return safe wrappers
  - on: [ port, usecase ]
    allowed:
      kind: 'return'
      definition: 'result.wrapper.future'
    forbidden:
      kind: 'return'
      type: 'Future'
```

### [4.3] Exceptions (`exceptions`)

**Purpose:** Enforce error handling flow

**Logic:** Who is a `producer` (throws), `propagator` (rethrows), or `boundary` (catches)?

#### Properties

**[a] `on`**: The component target
- **Type:** `String | List<String>`

**[b] `role`**: The semantic role regarding errors
- **Type:** `String`
- **Options:** `producer`, `boundary`, `consumer`, `propagator`

**[c] `required` | `forbidden`**: Required operations and Prohibited operations
- **Type:** `List<Map>`

**[c.1] `operation`**: The control flow action
- **Type:** `String | List<String>`
- **Options:** `throw`, `rethrow`, `catch_return`, `catch_throw`, `try_return`

**[c.2] `definition`**: Reference to a key in the `definitions` config
- **Type:** `String`

**[c.3] `type`**: Raw class name (used if no definition key exists)
- **Type:** `String`

**[e] `conversions`**: Exception-to-Failure mapping for boundaries
- **Type:** `List<Map>`

**[e.1] `from`**: The exception type caught
- **Type:** `String`

**[e.2] `to`**: The failure type returned
- **Type:** `String`

#### Example

```yaml
exceptions:
  # Repositories catch and return Failures
  - on: repository
    role: boundary
    required:
      - operation: 'catch_return'
        definition: 'result.failure'
    forbidden:
      - operation: 'throw'
    conversions:
      - from: 'exception.server'
        to: 'failure.server'
```

### [4.4] Structure (`members` & `annotations`)

**Purpose:** Enforce internal class structure

#### Members Properties

**[a] `on`**: The component target
- **Type:** `String | List<String>`

**[b] `required` | `allowed` | `forbidden`**: Members that must exist, Permitted members 
(whitelist), and Prohibited members (blacklist)
- **Type:** `List<Map>`

**[b.1] `kind`**: The member type target
- **Type:** `String | List<String>`
- **Options:** `method`, `field`, `getter`, `setter`, `constructor`, `override`

**[b.2] `identifier`**: Specific names or Regex patterns to match
- **Type:** `String | List<String>`

**[b.3] `visibility`**: The access level
- **Type:** `String`
- **Options:** `public`, `private`

**[b.4] `modifier`**: Required keywords
- **Type:** `String`
- **Options:** `final`, `const`, `static`, `late`

**[b.5] `action`**: Quick Fix action if member is missing
- **Type:** `String`

#### Example

```yaml
members:
  # Entities must be immutable
  - on: entity
    required:
      - kind: 'field'
        identifier: 'id'
      - kind: 'field'
        modifier: 'final'
    forbidden:
      - kind: 'setter'
        visibility: 'public'
```

### [4.5] Relationships (`relationships`)

**Purpose:** Enforce file parity (1-to-1 mappings)

**Logic:** "For every Method in a Port, there must be a UseCase file"

#### Properties

**[a] `on`**: The source component
- **Type:** `String`

**[b] `kind`**: What to iterate over
- **Type:** `String`
- **Options:** `class`, `method`

**[c] `visibility`**: Filter by visibility
- **Type:** `String`
- **Options:** `public`, `private`

**[d] `required`**: Target component that must exist
- **Type:** `Map`

**[d.1] `component`**: The architectural component to look for
- **Type:** `String`

**[d.2] `action`**: Quick Fix action if missing
- **Type:** `String`

#### Example

```yaml
relationships:
  # Every Port method needs a UseCase
  - on: 'domain.port'
    kind: 'method'
    visibility: 'public'
    required:
      component: 'domain.usecase'
      action: 'create_usecase'
```

---

## [5] 🤖 Automation (Actions & Templates)

The linter acts as a code generator when rules are broken.

### [5.1] Actions (`actions`)

Defines the logic for a Quick Fix. Uses a **Dart-like Expression Language** for variables.

#### Properties

**[a] `description`**: Human-readable name for the IDE
- **Type:** `String`

**[b] `template_id`**: Reference to template in `templates` section
- **Type:** `String`

**[c] `format`**: Whether to format generated code
- **Type:** `Boolean`

**[d] `format_line_length`**: Line length for formatting
- **Type:** `Integer`

**[e] `debug`**: Enable debug logging
- **Type:** `Boolean`

**[f] `trigger`**: When this action appears
- **Type:** `Map`

**[f.1] `error_code`**: The lint rule that triggers this
- **Type:** `String`

**[f.2] `component`**: The architectural component scope
- **Type:** `String`

**[g] `source`**: Where data comes from
- **Type:** `Map`

**[g.1] `scope`**: Source context
- **Type:** `String`
- **Options:** `current`, `related`

**[g.2] `element`**: AST node type to extract
- **Type:** `String`
- **Options:** `class`, `method`, `field`

**[h] `target`**: Where the new code goes
- **Type:** `Map`

**[h.1] `scope`**: Target context
- **Type:** `String`
- **Options:** `current`, `related`

**[h.2] `component`**: Destination component ID
- **Type:** `String`

**[i] `write`**: How to save the generated code
- **Type:** `Map`

**[i.1] `strategy`**: Write mode
- **Type:** `String`
- **Options:** `file`, `inject`, `replace`

**[i.2] `filename`**: Output filename template
- **Type:** `String`

**[i.3] `placement`**: *(for inject)* Where to insert
- **Type:** `String`
- **Options:** `start`, `end`

**[j] `variables`**: Data map for the template
- **Type:** `Map<String, dynamic>`
- **Values:** Can be strings, lists with switch/case logic, or complex expressions

#### Example

```yaml
actions:
  create_usecase:
    description: 'Generate Functional UseCase'
    template_id: 'usecase_functional'
    format: true
    format_line_length: 100
    debug: true
    
    trigger:
      error_code: 'arch_parity_missing'
      component: 'domain.port'
    
    source:
      scope: current
      element: method
    
    target:
      scope: related
      component: 'domain.usecase'
    
    write:
      strategy: file
      filename: '{{source.name.snakeCase}}.dart'
    
    variables:
      className: '{{source.name.pascalCase}}'
      repoVar: '_{{source.parent.name.camelCase}}'
```

### [5.2] Templates (`templates`)

Standard Mustache templates. Logic-less.

#### Properties

**[a] `file`**: Path to the Mustache template file
- **Type:** `String`

**[b] `description`**: Human-readable description
- **Type:** `String`

#### Example

```yaml
templates:
  usecase_template:
    file: 'templates/usecase.mustache'
    description: 'Standard UseCase template'
```

**Example template file (`templates/usecase.mustache`):**
```dart
class {{className}} extends {{baseClass}} {
final {{repoType}} {{repoVar}};

const {{className}}(this.{{repoVar}});

@override
{{returnType}} call({{parameters}}) {
// TODO: Implement
}
}
```

---

## [6] 🔗 References (Available Options)

### Component Options

| Option | Values | Description |
|:-------|:-------|:------------|
| **`mode`** | `file` | The component is the file itself (Default) |
| | `part` | The component is a symbol *inside* a file |
| | `namespace` | The component is just a folder |
| **`kind`** | `class`, `enum`, `mixin`, `extension`, `typedef` | Dart declaration types |
| **`modifier`** | `abstract`, `sealed`, `interface`, `base`, `final`, `mixin` | Dart keywords |

### Write Strategies

| Strategy | Description |
|:---------|:------------|
| **`file`** | Creates a new file or overwrites existing |
| **`inject`** | Inserts code into existing class body |
| **`replace`** | Replaces the source node entirely |

### Expression Engine Variables

Available in `actions.variables`:

*   **`source`**: The AST Node (Class, Method, Field)
    *   `.name`: String (with `.pascalCase`, `.snakeCase` filters)
    *   `.parent`: Parent node
    *   `.file.path`: Absolute path
    *   `.returnType`: TypeWrapper (methods)
    *   `.parameters`: ListWrapper (methods)

*   **`config`**: The Architecture Config
    *   `.definitionFor('key')`: Looks up type definition
    *   `.namesFor('componentId')`: Looks up naming patterns

*   **`definitions`**: Direct map access to definitions

---

## 🧠 Smart Resolution Logic

The linter uses a sophisticated **Component Refiner** to identify files. It doesn't just look at file paths; it looks at:

1.  **Path Depth**: Deeper matches are preferred
2.  **Naming Patterns**: Does the class name match `{{name}}Repository`?
3.  **Inheritance**: Does the class extend `BaseRepository`?
4.  **Structure**: Is it `abstract` vs `concrete`?

This ensures that even if you have an Interface (`AuthSource`) and Implementation (`AuthSourceImpl`) in the *same folder*, the linter correctly applies different rules to each.

### How the Resolution Engine Works

When a file is analyzed, the **Component Refiner** calculates a score to identify it. This allows `AuthSource` (Interface) and `AuthSourceImpl` (Implementation) to live in the same folder but be treated differently.

**Scoring Criteria:**
1.  **Path Match:** Deeper directory matches get higher scores
2.  **Mode:** `mode: file` beats `mode: part`
3.  **Naming:** Matches configured `{{name}}Pattern`
4.  **Inheritance:** Implements required base classes defined in `inheritances`
5.  **Structure:** Matches required `kind` (class/enum) and `modifier` (abstract/concrete)

*Example:* A concrete class `AuthImpl` will fail to match a component that requires `modifier: abstract`, forcing the resolver to pick the Implementation component instead.
```