# Architecture Lints 🏗️

A **configuration-driven**, **architecture-agnostic** linting engine for Dart and Flutter that 
transforms your architectural vision into enforceable code standards.

Unlike standard linters that enforce hardcoded opinions (e.g., "Always extend Bloc"), 
`architecture_lints` reads a **Policy Definition** from an `architecture.yaml` file in your project 
root. This allows you to define your **own** architectural rules, layers, and naming conventions.

It is the core engine powering packages like `architecture_clean`, but it can be used standalone to 
enforce any architectural style (MVVM, MVC, DDD, Layer-First, Feature-First).

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

1. [**Core Declarations**](#2-core-declarations-the-configurations)
2. [**Auxiliary Declarations**](#3-auxiliary)
3. [**Policies (The Rules)**](#4-policies-enforcing-behavior)
4. [**Automation (Code Generation)**](#5-automation-actions--templates)
5. [**Reference: Available Options**](#6-reference-available-options)

## [1] 🎯 Core Declarations (The Configurations)

The `architecture.yaml` file drives everything.

### [1.1] Modules (`modules`)

Modules represent the **Features** or high-level groupings of your application. The linter uses 
these definitions to map codebase files to specific functional boundaries. For example `Core`, 
`Shared`, `Profile`, `Auth`.

**Relationship:** A module usually acts as a container for multiple architectural layers.

<table>
  <thead>
    <tr>
      <th>Property</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>&lt;module_key&gt;</b></td>
      <td><code>String</code></td>
      <td><b>Definition</b></td>
      <td>
        The unique identifier for the module. This ID is used when referencing modules in 
        dependency rules
      </td>
    </tr>
    <tr>
      <td rowspan="2"><b>&lt;module_value&gt;</b></td>
      <td rowspan="2"><code>String</code> | <code>Map</code></td>
      <td><b>Shorthand</b></td>
      <td>
        <code>&lt;module_key&gt;: '&lt;path&gt;'</code><br>Simple path mapping for quick 
        definitions.
      </td>
    </tr>
    <tr>
      <td><b>Longhand</b></td>
      <td>
        <code>&lt;module_key&gt;: { path: '&lt;path&gt;', default: bool }</code><br>Full
        configuration for advanced options.
      </td>
    </tr>
    <tr>
      <td rowspan="3"><b>path</b></td>
      <td rowspan="3"><code>String</code></td>
      <td><b>Location + Token</b></td>
      <td>The root directory for this module relative to the project root.</td>
    </tr>
    <tr>
      <td><code>{{name}}</code></td>
      <td>Dynamic module indicator. The folder name becomes the module instance name.</td>
    </tr>
    <tr>
      <td><code>*</code></td>
      <td>Standard glob wildcard for ignoring intermediate folders.</td>
    </tr>
    <tr>
      <td><b>default</b></td>
      <td><code>Boolean</code></td>
      <td><b>Fallback</b></td>
      <td>
        If <code>true</code>, this module acts as the fallback for unmatched components.<br> 
        (Default: <code>false</code>)
      </td>
    </tr>
  </tbody>
</table>

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

### [1.2] Components (`components`)

Components represent the **Layers** or technical roles within a module.

Maps your file system structure to architectural concepts. This is the core taxonomy of your 
project.

- *Example:* `Entity`, `Repository`, `UseCase`, `Widget`.
- A component is defined by what it *is* (Structure) and where it *lives* (Path).

<table>
  <thead>
    <tr>
      <th>Property</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="2"><b>&lt;component_key&gt;</b></td>
      <td rowspan="2"><code>String</code></td>
      <td><b>Hierarchy</b></td>
      <td>
        Keys starting with <code>.</code> are treated as children. Their ID is concatenated with 
        the parent (e.g., <code>domain</code> + <code>.port</code> = <code>domain.port</code>).
      </td>
    </tr>
    <tr>
      <td><b>Inheritance</b></td>
      <td>Child components automatically inherit the <code>path</code> of their parent.</td>
    </tr>
    <tr>
      <td><b>&lt;component_value&gt;</b></td>
      <td><code>Map</code></td>
      <td><b>Structure</b></td>
      <td></td>
    </tr>
    <tr>
      <td><b>&lt;component_child&gt;</b></td>
      <td><code>Map</code></td>
      <td><b>Recursive Structure</b></td>
      <td>Any thing that starts with <code>.</code> is treated as a child of the component.</td>
    </tr>
    <tr>
      <td rowspan="3"><b>mode</b></td>
      <td rowspan="3"><code>Enum</code></td>
      <td><code>file</code>(<b>default</b>)</td>
      <td>
        Represents a specific code unit (e.g., a class in a file). Matches based on file name and 
        content
      </td>
    </tr>
    <tr>
      <td><code>part</code></td>
      <td>
        Represents a symbol defined *inside* a file (e.g., an <code>Event</code> class defined 
        within a Bloc file). Use this for detailed structural checks within a file
      </td>
    </tr>
    <tr>
      <td><code>namespace</code></td>
      <td>
        Represents a folder or layer container. Matches directories, never specific files. 
        Use this for parent keys (e.g., <code>domain</code>)
      </td>
    </tr>
    <tr>
      <td><b>path</b></td>
      <td><code>String</code> | <code>List&lt;String&gt;</code></td>
      <td><b>Location</b></td>
      <td>The directory name(s) relative to the parent component path.</td>
    </tr>
    <tr>
      <td rowspan="5"><b>kind</b></td>
      <td rowspan="5"><code>Enum</code> | <code>List&lt;Enum&gt;</code></td>
      <td><code>class</code></td>
      <td rowspan="5">
        Enforces the specific Dart declaration type. Matches the language keyword.
      </td>
    </tr>
    <tr><td><code>enum</code></td></tr>
    <tr><td><code>mixin</code></td></tr>
    <tr><td><code>extension</code></td></tr>
    <tr><td><code>typedef</code></td></tr>
    <tr>
      <td rowspan="6"><b>modifier</b></td>
      <td rowspan="6"><code>Enum</code> | <code>List&lt;Enum&gt;</code></td>
      <td><code>abstract</code></td>
      <td rowspan="6">
        Enforces specific Dart keywords on the declaration to control inheritance and visibility.
      </td>
    </tr>
    <tr><td><code>sealed</code></td></tr>
    <tr><td><code>interface</code></td></tr>
    <tr><td><code>base</code></td></tr>
    <tr><td><code>final</code></td></tr>
    <tr><td><code>mixin</code></td></tr>
    <tr>
      <td rowspan="3"><b>pattern | antipattern</b></td>
      <td rowspan="3"><code>String</code> | <code>List&lt;String&gt;</code></td>
      <td><b>Regex + Tokens</b></td>
      <td>
        A required (<code>pattern</code>) and forbidden (<code>antipattern</code>) naming pattern 
        used to guide users to follow and away from bad naming habits respectively.
      </td>
    </tr>
    <tr>
      <td><code>{{name}}</code></td>
      <td>PascalCase naming convention.</td>
    </tr>
    <tr>
      <td><code>{{affix}}</code></td>
      <td>Wildcard naming convention.</td>
    </tr>
    <tr>
      <td rowspan="13"><b>grammar</b></td>
      <td rowspan="13"><code>String</code> | <code>List&lt;String&gt;</code></td>
      <td><b>Regex + Tokens</b></td>
      <td>Semantic naming patterns using Natural Language Processing (NLP) parts of speech.</td>
    </tr>
    <tr>
      <td><code>{{noun}}</code></td>
      <td rowspan="4">
        Semantic naming patterns using Natural Language Processing (NLP) parts of speech.
      </td>
    </tr>
    <tr><td><code>{{noun.phrase}}</code></td></tr>
    <tr><td><code>{{noun.singular}}</code></td></tr>
    <tr><td><code>{{noun.plural}}</code></td></tr>
    <tr>
      <td><code>{{verb}}</code></td>
      <td rowspan="4">
        Semantic naming patterns using Natural Language Processing (NLP) parts of speech.
      </td>
    </tr>
    <tr><td><code>{{verb.present}}</code></td></tr>
    <tr><td><code>{{verb.past}}</code></td></tr>
    <tr><td><code>{{verb.gerund}}</code></td></tr>
    <tr>
      <td><code>{{adjective}}</code></td>
      <td rowspan="4">
        Semantic naming patterns using Natural Language Processing (NLP) parts of speech.
      </td>
    </tr>
    <tr><td><code>{{adverb}}</code></td></tr>
    <tr><td><code>{{preposition}}</code></td></tr>
    <tr><td><code>{{conjunction}}</code></td></tr>
  </tbody>
</table>

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

#### 🧠 Resolution Logic

The linter uses a Smart Resolution Logic to identify files by calculating a score. This allows an 
Interface (`AuthSource`) and Implementation (`AuthSourceImpl`) in the same folder to be treated 
differently.

**Scoring Criteria:**

1. **Path Match:** Deeper directory matches get higher scores.
2. **Mode:** `mode: file` beats `mode: part`.
3. **Naming:** Matches configured `{{name}}Pattern`.
4. **Inheritance:** Implements required base classes defined in `inheritances`.
5. **Structure:** Matches required `kind` and `modifier`.

*Example:* A concrete class `AuthImpl` will fail to match a component requiring 
`modifier: abstract`, forcing the resolver to pick the Implementation component instead.

The Linter combines these to identify a file:
> `lib/features/auth/domain/usecases/login.dart`
>
> - **Module:** `auth` (Derived from `features/{{name}}`)
> - **Component:** `domain.usecase` (Derived from path `domain/usecases`)

---

## [2] 🧩 Auxiliary Declarations

### [2.1] Types (`definitions`)

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

### [2.2] Vocabularies (`vocabularies`)

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

## [3] 📜 Policies (Enforcing Behavior)

Policies define what is required, allowed, or forbidden.

### [3.1] Dependencies (`dependencies`)

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

### [3.2] Type Safety (`type_safeties`)

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

### [3.3] Exceptions (`exceptions`)

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

### [3.4] Structure (`members` & `annotations`)

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

### [3.5] Relationships (`relationships`)

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

## [4] 🤖 Automation (Actions & Templates)

The linter acts as a code generator when rules are broken.

### [4.1] Actions (`actions`)

Defines the logic for a Quick Fix. Uses a **Mustache Like Expression Language** for variables.

#### [4.1.1] Metadata

Basic configuration for the Quick Fix.

| Property                 | Type      | Description                      |
|:-------------------------|:----------|:---------------------------------|
| **`description`**        | `String`  | Human-readable name.             |
| **`template_id`**        | `String`  | Reference to template key.       |
| **`debug`**              | `Boolean` | Enable logging in the generated. |
| **`format`**             | `Boolean` | Whether to format generated code |
| **`format_line_length`** | `Integer` | Line length for formatting       |

#### [4.1.2] Trigger, Source & Target Context

Determines when the action appears, where data is extracted from, and where the resulting code is 
injected.

<table>
  <thead>
    <tr>
      <th>Property</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>trigger.error_code</b></td>
      <td><code>String</code></td>
      <td>—</td>
      <td>The lint rule triggering this.</td>
    </tr>
    <tr>
      <td><b>trigger.component</b></td>
      <td><code>String</code></td>
      <td>—</td>
      <td>The component scope.</td>
    </tr>
    <tr>
      <td rowspan="2"><b>source.scope</b></td>
      <td rowspan="2"><code>Enum</code></td>
      <td><code>current</code></td>
      <td>The current file context.</td>
    </tr>
    <tr>
      <td><code>related</code></td>
      <td>The related file context.</td>
    </tr>
    <tr>
      <td rowspan="3"><b>source.element</b></td>
      <td rowspan="3"><code>Enum</code></td>
      <td><code>class</code></td>
      <td>The class definition node.</td>
    </tr>
    <tr>
      <td><code>method</code></td>
      <td>The specific method node.</td>
    </tr>
    <tr>
      <td><code>field</code></td>
      <td>The property or field node.</td>
    </tr>
    <tr>
      <td rowspan="2"><b>target.scope</b></td>
      <td rowspan="2"><code>Enum</code></td>
      <td><code>current</code></td>
      <td>Write to the current file.</td>
    </tr>
    <tr>
      <td><code>related</code></td>
      <td>Write to the related file.</td>
    </tr>
    <tr>
      <td><b>target.component</b></td>
      <td><code>String</code></td>
      <td>—</td>
      <td>Destination component name.</td>
    </tr>
  </tbody>
</table>

#### [4.1.3] Write Strategy

How the generated code is saved.

<table>
  <thead>
    <tr>
      <th>Property</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="3"><b>write.strategy</b></td>
      <td rowspan="3"><code>Enum</code></td>
      <td><code>file</code></td>
      <td>Sets the specific output filename.</td>
    </tr>
    <tr>
      <td><code>inject</code></td>
      <td>Uses an existing file and identifies an insertion point.</td>
    </tr>
    <tr>
      <td><code>replace</code></td>
      <td>Overwrites the output file entirely.</td>
    </tr>
    <tr>
      <td><b>write.filename</b></td>
      <td><code>String</code></td>
      <td>—</td>
      <td>The specific output filename (required for <code>file</code> strategy).</td>
    </tr>
    <tr>
      <td rowspan="2"><b>write.placement</b></td>
      <td rowspan="2"><code>Enum</code></td>
      <td><code>start</code></td>
      <td>Places content at the beginning of the file/block.</td>
    </tr>
    <tr>
      <td><code>end</code></td>
      <td>Places content at the end of the file/block.</td>
    </tr>
  </tbody>
</table>

#### [4.1.4] Expression Engine

Built-in methods and variables in `actions.variables`

- **`source`**: The AST Node (Class, Method, Field)
  - `.name`: String (with `.pascalCase`, `.snakeCase` filters)
  - `.parent`: Parent node
  - `.file.path`: Absolute path
  - `.returnType`: TypeWrapper (methods)
  - `.parameters`: ListWrapper (methods)

- **`config`**: The Architecture Config
  - `.definitionFor('key')`: Looks up type definition
  - `.namesFor('componentId')`: Looks up naming patterns

#### [4.1.5] Variables & Expressions

Maps data from the `source` to the `template`. This uses a Mustache-like expression language.

**Simple References:** Direct access to properties

```yaml
variables:
  className: '{{source.name.pascalCase}}'
  repoName: '{{source.parent.name}}'
```

**Conditional Switch Logic:** Use a list of maps to handle "if/else" logic

```yaml
variables:
  baseDef:
    select:
      - if: source.parameters.isEmpty
        value: config.definitionFor('usecase.nullary')
      - else: config.definitionFor('usecase.unary')
```

**Complex Mappings & Lists:** Iterating over lists or mapping objects

```yaml
variables:
  params:
    type: list
    from: source.parameters
    map:
      .name: item.name.value
      .type: item.type.unwrapped.value
```

**Common Filters:** Available on string properties:

- `pascalCase`
- `snakeCase`
- `camelCase`
- `extractGeneric(index=1)`

#### Full Example

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

### [4.2] Templates (`templates`)

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
