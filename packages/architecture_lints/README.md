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

1.  [**Concepts & Philosophies**](#1--concepts--philosophies)
2.  [**Core Declarations**](#2--core-declarations-the-configurations)
3.  [**Auxiliary Declarations**](#3--auxiliary-declarations)
4.  [**Policies (The Rules)**](#4--policies-enforcing-behavior)
5.  [**Automation (Code Generation)**](#5--automation-actions--templates)

---

## [1] 💡 Concepts & Philosophies

To effectively lint a large project, we must understand its structure on two axes:

### **Modules (Horizontal Slicing)**
Modules represent the **Features** or high-level groupings of your application.
-   *Example:* `Core`, `Shared`, `Profile`, `Auth`.
-   A module usually contains multiple layers.

### **Components (Vertical Slicing)**
Components represent the **Layers** or technical roles within a module.
-   *Example:* `Entity`, `Repository`, `UseCase`, `Widget`.
-   A component is defined by what it *is* (Structure) and where it *lives* (Path).

The Linter combines these to identify a file:
> `lib/features/auth/domain/usecases/login.dart`
>
> -   **Module:** `auth` (Derived from `features/{{name}}`)
> -   **Component:** `domain.usecase` (Derived from path `domain/usecases`)

---

## [2] 🎯 Core Declarations (The Configurations)

The `architecture.yaml` file drives everything.

### [2.1] Modules (`modules`)

Modules represent the **Features** or high-level groupings of your application. The linter uses
these definitions to map codebase files to specific functional boundaries. For example `Core`,
`Shared`, `Profile`, `Auth`.

**Relationship:** A module usually acts as a container for multiple architectural layers.

#### Definitions

```yaml
modules:
  <module_key>: <module_value>
```

<table>
  <thead>
    <tr>
      <th>Name</th>
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
        dependency rules.
      </td>
    </tr>
    <tr>
      <td rowspan="2"><b>&lt;module_value&gt;</b></td>
      <td><code>String</code></td>
      <td><b>Shorthand</b></td>
      <td>
        <code>&lt;module_key&gt;: '&lt;path&gt;'</code><br>Simple path mapping for quick 
        definitions.
      </td>
    </tr>
    <tr>
      <td><code>Map</code></td>
      <td><b>Longhand</b></td>
      <td>
        <code>&lt;module_key&gt;: { path: '&lt;path&gt;', default: bool }</code><br>Full
        configuration for advanced options.
      </td>
    </tr>
  </tbody>
</table>

> **Note:**
> - `<module_value>` can be only one of the two forms (**shorthand** or **longhand**).

#### Properties

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="3"><b>path</b></td>
      <td><code>String</code></td>
      <td><b>Location + Token</b></td>
      <td>The root directory for this module relative to the project root.</td>
    </tr>
    <tr>
      <td rowspan="2"><code>Token</code></td>
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

### [2.2] Components (`components`)

Components represent the **Layers** or technical roles within a module.

Maps your file system structure to architectural concepts. This is the core taxonomy of your
project.

- *Example:* `Entity`, `Repository`, `UseCase`, `Widget`.
- A component is defined by what it *is* (Structure) and where it *lives* (Path).

#### Definitions

```yaml
components:
  <component_key>: 
    <component_property>
    <component_property>
    
    .<component_child>
    .<component_child>
```

<table>
  <thead>
    <tr>
      <th>Name</th>
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
  </tbody>
</table>

#### Properties

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="3"><b>mode</b></td>
      <td rowspan="3"><code>Enum</code></td>
      <td><code>file</code>(<b>default</b>)</td>
      <td>
        Represents a specific code unit (e.g., a class in a file). Matches based on file name and 
        content.
      </td>
    </tr>
    <tr>
      <td><code>part</code></td>
      <td>
        Represents a symbol defined *inside* a file (e.g., an <code>Event</code> class defined 
        within a Bloc file). Use this for detailed structural checks within a file.
      </td>
    </tr>
    <tr>
      <td><code>namespace</code></td>
      <td>
        Represents a folder or layer container. Matches directories, never specific files. 
        Use this for parent keys (e.g., <code>domain</code>).
      </td>
    </tr>
    <tr>
      <td><b>path</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Location</b></td>
      <td>The directory name(s) relative to the parent component path.</td>
    </tr>
    <tr>
      <td rowspan="5"><b>kind</b></td>
      <td rowspan="5"><code>Enum</code>,<br><code>Set&lt;Enum&gt;</code></td>
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
      <td rowspan="6"><code>Enum</code>,<br><code>Set&lt;Enum&gt;</code></td>
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
      <td rowspan="4"><b>pattern,<br>antipattern</b></td>
      <td rowspan="2"><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td rowspan="2"><b>Regex + Tokens</b></td>
      <td>
        A required (<code>pattern</code>) naming pattern used to guide users to follow good naming 
        habits.
      </td>
    </tr>
    <tr>
      <td>
        A forbidden (<code>antipattern</code>) naming pattern used to guide away from bad naming 
        habits.
      </td>
    </tr>
    <tr>
      <td rowspan="2"><code>Token</code></td>
      <td><code>{{name}}</code></td>
      <td>PascalCase naming convention.</td>
    </tr>
    <tr>
      <td><code>{{affix}}</code></td>
      <td>Wildcard naming convention.</td>
    </tr>
    <tr>
      <td rowspan="13"><b>grammar</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Regex + Tokens</b></td>
      <td>Semantic naming patterns using Natural Language Processing (NLP) parts of speech.</td>
    </tr>
    <tr>
      <td rowspan="12"><code>Token</code></td>
      <td><code>{{noun}}</code></td>
      <td rowspan="4">
        Noun related Natural Language Processing (NLP) tokens.
      </td>
    </tr>
    <tr><td><code>{{noun.phrase}}</code></td></tr>
    <tr><td><code>{{noun.singular}}</code></td></tr>
    <tr><td><code>{{noun.plural}}</code></td></tr>
    <tr>
      <td><code>{{verb}}</code></td>
      <td rowspan="4">
        Verb related Natural Language Processing (NLP) tokens.
      </td>
    </tr>
    <tr><td><code>{{verb.present}}</code></td></tr>
    <tr><td><code>{{verb.past}}</code></td></tr>
    <tr><td><code>{{verb.gerund}}</code></td></tr>
    <tr>
      <td><code>{{adjective}}</code></td>
      <td rowspan="4">
        Other Language Processing (NLP) tokens.
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

---

## [3] 🧩 Auxiliary Declarations

### [3.1] Types (`definitions`)

Maps abstract concepts (like "Result Wrapper" or "Service Locator") to concrete Dart types. This
decouples your rules from specific class names.

#### Definitions

```yaml
definitions:
  <group_key>:
    <type_key>: <type_value>
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>&lt;group_key&gt;</b></td>
      <td><code>String</code></td>
      <td><b>Group</b></td>
      <td>A logical grouping (e.g., 'usecase', 'result').</td>
    </tr>
    <tr>
      <td><b>&lt;type_key&gt;</b></td>
      <td><code>String</code></td>
      <td><b>Key</b></td>
      <td>The unique identifier within the group.</td>
    </tr>
    <tr>
      <td rowspan="2"><b>&lt;type_value&gt;</b></td>
      <td><code>String</code></td>
      <td><b>Shorthand</b></td>
      <td>
        <code>key: 'ClassName'</code>. Inherits previous import.
      </td>
    </tr>
    <tr>
      <td><code>Map</code></td>
      <td><b>Detailed</b></td>
      <td>
        <code>key: { type: 'ClassName', import: '...' }</code>. Explicit config.
      </td>
    </tr>
  </tbody>
</table>

#### Properties

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>type</b></td>
      <td><code>String</code></td>
      <td><b>Class</b></td>
      <td>The raw Dart class name.</td>
    </tr>
    <tr>
      <td><b>import</b></td>
      <td><code>String</code></td>
      <td><b>URI</b></td>
      <td>The package URI. If omitted, inherits from the previous entry.</td>
    </tr>
    <tr>
      <td><b>argument</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Generics</b></td>
      <td>
        Expected generic type parameters (Recursive structure). <code>'*'</code> matches any.
      </td>
    </tr>
  </tbody>
</table>

#### Example

```yaml
definitions:
  # Domain Types
  usecase:
    .base:
      type: 'Usecase'
      import: 'package:my_app/core/usecase.dart'
    # Inherits import from .base
    .unary: 'UnaryUsecase' 
    
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
(e.g., "UseCases must be Verb-Noun").

#### Definitions

```yaml
vocabularies:
  nouns: <list>
  verbs: <list>
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>nouns</b></td>
      <td><code>List&lt;String&gt;</code></td>
      <td><b>Terms</b></td>
      <td>Domain-specific noun terms (e.g., 'auth', 'kyc').</td>
    </tr>
    <tr>
      <td><b>verbs</b></td>
      <td><code>List&lt;String&gt;</code></td>
      <td><b>Actions</b></td>
      <td>Domain-specific verb terms (e.g., 'upsert', 'rebase').</td>
    </tr>
  </tbody>
</table>

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

Enforce the Dependency Rule (Architecture Boundaries).

#### Definitions

```yaml
dependencies:
  - on: <component_id>
    <allowed | forbidden>
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>on</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Target</b></td>
      <td>The component or layer target.</td>
    </tr>
    <tr>
      <td><b>allowed</b></td>
      <td><code>Map</code></td>
      <td><b>Whitelist</b></td>
      <td>If defined, the component may ONLY import from these sources.</td>
    </tr>
    <tr>
      <td><b>forbidden</b></td>
      <td><code>Map</code></td>
      <td><b>Blacklist</b></td>
      <td>The component must NOT import from these sources.</td>
    </tr>
  </tbody>
</table>

#### Properties

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>component</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Reference</b></td>
      <td>List of architectural components to check against.</td>
    </tr>
    <tr>
      <td><b>import</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Pattern</b></td>
      <td>List of URI patterns. Supports glob <code>**</code>.</td>
    </tr>
  </tbody>
</table>

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

Enforce method signatures.

#### Definitions

```yaml
type_safeties:
  - on: <component_id>
    <allowed | forbidden>
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>on</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Target</b></td>
      <td>The component target.</td>
    </tr>
    <tr>
      <td><b>allowed</b></td>
      <td><code>Map</code></td>
      <td><b>Whitelist</b></td>
      <td>Types MUST match one of these.</td>
    </tr>
    <tr>
      <td><b>forbidden</b></td>
      <td><code>Map</code></td>
      <td><b>Blacklist</b></td>
      <td>Types MUST NOT match any of these.</td>
    </tr>
  </tbody>
</table>

#### Properties

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="2"><b>kind</b></td>
      <td rowspan="2"><code>Enum</code></td>
      <td><code>return</code></td>
      <td rowspan="2">The context of the check (return type or parameter).</td>
    </tr>
    <tr><td><code>parameter</code></td></tr>
    <tr>
      <td><b>identifier</b></td>
      <td><code>String</code></td>
      <td><b>Param Name</b></td>
      <td>(Only for kind: parameter) The parameter name to match.</td>
    </tr>
    <tr>
      <td><b>definition</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Ref</b></td>
      <td>Reference to a key in the <code>definitions</code> config.</td>
    </tr>
    <tr>
      <td><b>type</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Raw</b></td>
      <td>Raw class name string (e.g., 'int', 'Future').</td>
    </tr>
    <tr>
      <td><b>component</b></td>
      <td><code>String</code></td>
      <td><b>Arch Ref</b></td>
      <td>Reference to an architectural component.</td>
    </tr>
  </tbody>
</table>

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

Enforce error handling flow.

#### Definitions

```yaml
exceptions:
  - on: <component_id>
    role: <role>
    <required | forbidden>
    conversions: ...
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>on</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Target</b></td>
      <td>The component target.</td>
    </tr>
    <tr>
      <td rowspan="4"><b>role</b></td>
      <td rowspan="4"><code>Enum</code></td>
      <td><code>producer</code></td>
      <td rowspan="4">The semantic role regarding errors.</td>
    </tr>
    <tr><td><code>boundary</code></td></tr>
    <tr><td><code>consumer</code></td></tr>
    <tr><td><code>propagator</code></td></tr>
    <tr>
      <td><b>required</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Must</b></td>
      <td>Required operations.</td>
    </tr>
    <tr>
      <td><b>forbidden</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Must Not</b></td>
      <td>Prohibited operations.</td>
    </tr>
    <tr>
      <td><b>conversions</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Map</b></td>
      <td>Exception-to-Failure mapping for boundaries.</td>
    </tr>
  </tbody>
</table>

#### Properties (inside required/forbidden)

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="5"><b>operation</b></td>
      <td rowspan="5"><code>Enum</code>,<br><code>List&lt;Enum&gt;</code></td>
      <td><code>throw</code></td>
      <td rowspan="5">The control flow action.</td>
    </tr>
    <tr><td><code>rethrow</code></td></tr>
    <tr><td><code>catch_return</code></td></tr>
    <tr><td><code>catch_throw</code></td></tr>
    <tr><td><code>try_return</code></td></tr>
    <tr>
      <td><b>definition</b></td>
      <td><code>String</code></td>
      <td><b>Ref</b></td>
      <td>Reference to a key in the <code>definitions</code> config.</td>
    </tr>
    <tr>
      <td><b>type</b></td>
      <td><code>String</code></td>
      <td><b>Raw</b></td>
      <td>Raw class name (used if no definition key exists).</td>
    </tr>
  </tbody>
</table>

#### Properties (inside conversions)

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>from</b></td>
      <td><code>String</code></td>
      <td><b>Exception</b></td>
      <td>The exception type caught (reference to definitions).</td>
    </tr>
    <tr>
      <td><b>to</b></td>
      <td><code>String</code></td>
      <td><b>Failure</b></td>
      <td>The failure type returned (reference to definitions).</td>
    </tr>
  </tbody>
</table>

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

### [4.4] Structure

This section enforces internal class composition.

#### [4.4.1] Inheritances (`inheritances`)
Enforces base class requirements (`extends`, `implements`, `with`).

##### Definitions

```yaml
inheritances:
  - on: <component_id>
    <required | forbidden>
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>on</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Target</b></td>
      <td>Target component ID.</td>
    </tr>
    <tr>
      <td><b>required</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Must</b></td>
      <td>List of types the component MUST inherit.</td>
    </tr>
    <tr>
      <td><b>forbidden</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Must Not</b></td>
      <td>List of types the component MUST NOT inherit.</td>
    </tr>
  </tbody>
</table>

##### Properties (inside required/forbidden)

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>type</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Class</b></td>
      <td>Raw class name (e.g., 'Entity').</td>
    </tr>
    <tr>
      <td><b>import</b></td>
      <td><code>String</code></td>
      <td><b>URI</b></td>
      <td>The package URI.</td>
    </tr>
    <tr>
      <td><b>definition</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Ref</b></td>
      <td>Reference to a <code>definitions</code> key.</td>
    </tr>
    <tr>
      <td><b>component</b></td>
      <td><code>String</code></td>
      <td><b>Arch</b></td>
      <td>Reference to another architectural component ID.</td>
    </tr>
  </tbody>
</table>

##### Example

```yaml
inheritances:
  # Entities must extend the base Entity class
  - on: entity
    required:
      - type: 'Entity'
        import: 'package:core/entity/entity.dart'

  # Repositories must implement their corresponding Port
  - on: repository
    required:
      - component: 'port'
```

#### [4.4.2] Members (`members`)
Enforces rules on class members (fields, methods, constructors).

##### Definitions

```yaml
members:
  - on: <component_id>
    <required | allowed | forbidden>
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>on</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Target</b></td>
      <td>Target component ID.</td>
    </tr>
    <tr>
      <td><b>required</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Must</b></td>
      <td>Members that must exist.</td>
    </tr>
    <tr>
      <td><b>allowed</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Whitelist</b></td>
      <td>Permitted members (whitelist).</td>
    </tr>
    <tr>
      <td><b>forbidden</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Blacklist</b></td>
      <td>Prohibited members.</td>
    </tr>
  </tbody>
</table>

##### Properties

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="6"><b>kind</b></td>
      <td rowspan="6"><code>Enum</code>,<br><code>List&lt;Enum&gt;</code></td>
      <td><code>method</code></td>
      <td rowspan="6">The member type target.</td>
    </tr>
    <tr><td><code>field</code></td></tr>
    <tr><td><code>getter</code></td></tr>
    <tr><td><code>setter</code></td></tr>
    <tr><td><code>constructor</code></td></tr>
    <tr><td><code>override</code></td></tr>
    <tr>
      <td><b>identifier</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Name</b></td>
      <td>Specific names or Regex patterns to match.</td>
    </tr>
    <tr>
      <td rowspan="2"><b>visibility</b></td>
      <td rowspan="2"><code>Enum</code></td>
      <td><code>public</code></td>
      <td rowspan="2">The access level.</td>
    </tr>
    <tr><td><code>private</code></td></tr>
    <tr>
      <td rowspan="4"><b>modifier</b></td>
      <td rowspan="4"><code>Enum</code>,<br><code>List&lt;Enum&gt;</code></td>
      <td><code>final</code></td>
      <td rowspan="4">Required keywords.</td>
    </tr>
    <tr><td><code>const</code></td></tr>
    <tr><td><code>static</code></td></tr>
    <tr><td><code>late</code></td></tr>
    <tr>
      <td><b>action</b></td>
      <td><code>String</code></td>
      <td><b>Fix</b></td>
      <td>Quick Fix action ID if member is missing.</td>
    </tr>
  </tbody>
</table>

##### Example

```yaml
members:
  # Entities must be immutable and have an 'id'
  - on: entity
    required:
      - kind: field
        identifier: 'id'
      - kind: field
        modifier: 'final'
    forbidden:
      - kind: setter
        visibility: public
```

#### [4.4.3] Annotations (`annotations`)
Enforces metadata (Annotations) on classes.

##### Definitions

```yaml
annotations:
  - on: <component_id>
    mode: <mode>
    <required | forbidden>
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>on</b></td>
      <td><code>String</code></td>
      <td><b>Target</b></td>
      <td>Target component ID.</td>
    </tr>
    <tr>
      <td rowspan="2"><b>mode</b></td>
      <td rowspan="2"><code>Enum</code></td>
      <td><code>strict</code></td>
      <td rowspan="2">Controls strictness regarding unlisted annotations.</td>
    </tr>
    <tr><td><code>implicit</code></td></tr>
    <tr>
      <td><b>required</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Must</b></td>
      <td>Annotations that MUST exist.</td>
    </tr>
    <tr>
      <td><b>forbidden</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Must Not</b></td>
      <td>Annotations that MUST NOT exist.</td>
    </tr>
  </tbody>
</table>

##### Properties (inside required/forbidden)

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>type</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Class</b></td>
      <td>Annotation class name.</td>
    </tr>
    <tr>
      <td><b>import</b></td>
      <td><code>String</code></td>
      <td><b>URI</b></td>
      <td>Package URI.</td>
    </tr>
  </tbody>
</table>

##### Example

```yaml
annotations:
  # UseCases must be injectable. No other framework annotations allowed.
  - on: usecase
    mode: strict
    required:
      - type: 'Injectable'
        import: 'package:injectable/injectable.dart'
```

### [4.5] Relationships (`relationships`)

Enforce file parity (1-to-1 mappings).

#### Definitions

```yaml
relationships:
  - on: <component_id>
    kind: <kind>
    required: ...
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>on</b></td>
      <td><code>String</code></td>
      <td><b>Source</b></td>
      <td>The source component.</td>
    </tr>
    <tr>
      <td rowspan="2"><b>kind</b></td>
      <td rowspan="2"><code>Enum</code></td>
      <td><code>class</code></td>
      <td rowspan="2">What to iterate over.</td>
    </tr>
    <tr><td><code>method</code></td></tr>
    <tr>
      <td><b>visibility</b></td>
      <td><code>Enum</code></td>
      <td><code>public</code></td>
      <td>Filter by visibility.</td>
    </tr>
    <tr>
      <td><b>required</b></td>
      <td><code>Map</code></td>
      <td><b>Target</b></td>
      <td>Target component that must exist.</td>
    </tr>
  </tbody>
</table>

#### Properties (inside required)

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>component</b></td>
      <td><code>String</code></td>
      <td><b>Target</b></td>
      <td>The architectural component to look for.</td>
    </tr>
    <tr>
      <td><b>action</b></td>
      <td><code>String</code></td>
      <td><b>Fix</b></td>
      <td>Quick Fix action ID if missing.</td>
    </tr>
  </tbody>
</table>

#### Example

```yaml
relationships:
  # Every Port method needs a UseCase
  - on: domain.port
    kind: method
    visibility: public
    required:
      component: domain.usecase
      action: create_usecase
```

### [4.6] Usage (`usages`)
Bans specific coding patterns (e.g., global access).

#### Definitions

```yaml
usages:
  - on: <component_id>
    forbidden: ...
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>on</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Target</b></td>
      <td>The component target.</td>
    </tr>
    <tr>
      <td><b>forbidden</b></td>
      <td><code>List&lt;Map&gt;</code></td>
      <td><b>Blacklist</b></td>
      <td>List of disallowed usage patterns.</td>
    </tr>
  </tbody>
</table>

#### Properties (inside forbidden)

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="2"><b>kind</b></td>
      <td rowspan="2"><code>Enum</code></td>
      <td><code>access</code></td>
      <td rowspan="2">Type of usage.</td>
    </tr>
    <tr><td><code>instantiation</code></td></tr>
    <tr>
      <td><b>definition</b></td>
      <td><code>String</code></td>
      <td><b>Ref</b></td>
      <td>Reference to service definition.</td>
    </tr>
    <tr>
      <td><b>component</b></td>
      <td><code>String</code>,<br><code>List&lt;String&gt;</code></td>
      <td><b>Arch</b></td>
      <td>Reference to architectural component.</td>
    </tr>
  </tbody>
</table>

#### Example

```yaml
usages:
  - on: domain
    forbidden:
      kind: access
      definition: service.locator
```

---

## [5] 🤖 Automation (Actions & Templates)

The linter acts as a code generator when rules are broken.

### [5.1] Actions (`actions`)

Defines the logic for a Quick Fix. Uses a **Dart-like Expression Language** for variables.

#### Definitions

```yaml
actions:
  <action_id>:
    <global_properties>
    trigger: ...
    source: ...
    target: ...
    write: ...
    variables: ...
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>&lt;action_id&gt;</b></td>
      <td><code>String</code></td>
      <td><b>ID</b></td>
      <td>Unique identifier for the action.</td>
    </tr>
    <tr>
      <td><b>description</b></td>
      <td><code>String</code></td>
      <td><b>Label</b></td>
      <td>Human-readable name for the IDE.</td>
    </tr>
    <tr>
      <td><b>template_id</b></td>
      <td><code>String</code></td>
      <td><b>Ref</b></td>
      <td>Reference to template key.</td>
    </tr>
    <tr>
      <td><b>debug</b></td>
      <td><code>Boolean</code></td>
      <td><b>Log</b></td>
      <td>Enable debug logging.</td>
    </tr>
  </tbody>
</table>

#### [5.1.1] Trigger Configuration
Determines when the action appears.

| Name             | Type     | Value | Description                    |
|:-----------------|:---------|:------|:-------------------------------|
| **`trigger`**    | `Map`    |       | Configuration block.           |
| **`error_code`** | `String` |       | The lint rule triggering this. |
| **`component`**  | `String` |       | The component scope.           |

#### [5.1.2] Source & Target Context
Determines where data comes from and where code goes.

| Name            | Type     | Value                      | Description                |
|:----------------|:---------|:---------------------------|:---------------------------|
| **`source`**    | `Map`    |                            | Input context.             |
| **`scope`**     | `Enum`   | `current`, `related`       | Context of the input data. |
| **`element`**   | `Enum`   | `class`, `method`, `field` | AST node to extract.       |
| **`target`**    | `Map`    |                            | Output context.            |
| **`scope`**     | `Enum`   | `current`, `related`       | Context for output.        |
| **`component`** | `String` |                            | Destination component ID.  |

#### [5.1.3] Write Strategy
How the generated code is saved.

| Name            | Type     | Value                       | Description                   |
|:----------------|:---------|:----------------------------|:------------------------------|
| **`write`**     | `Map`    |                             | Write configuration block.    |
| **`strategy`**  | `Enum`   | `file`, `inject`, `replace` | Write mode.                   |
| **`filename`**  | `String` |                             | Output filename template.     |
| **`placement`** | `Enum`   | `start`, `end`              | Where to insert (for inject). |

#### [5.1.4] Variables & Expressions
Maps data from the `source` to the `template`. This uses a Dart-like expression language.

| Name            | Type  | Description                                         |
|:----------------|:------|:----------------------------------------------------|
| **`variables`** | `Map` | Map of keys to dynamic values used in the template. |

**Common Variable Strategies:**

1.  **Simple References**: Direct access to properties (e.g., `className: '{{source.name.pascalCase}}'`).
2.  **Conditional Switch Logic**: Use a list of maps to handle "if/else" logic.
3.  **Complex Mappings**: Iterating over lists or mapping objects (e.g., extracting parameters).
4.  **Common Filters**: `| pascalCase`, `| snakeCase`, `| camelCase`.

#### Example

```yaml
actions:
  create_usecase:
    description: 'Generate UseCase'
    template_id: 'usecase_template'
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
      # Switch logic
      baseDef:
        select:
          - if: source.parameters.isEmpty
            value: 'NullaryUsecase'
          - else: 'UnaryUsecase'
            
      # Simple reference
      className: '{{source.name.pascalCase}}'
      
      # List mapping
      paramsList:
        type: list
        from: source.parameters
        map:
          name: item.name
```

### [5.2] Templates (`templates`)
Standard Mustache templates. Logic-less.

#### Definitions

```yaml
templates:
  <template_id>:
    file: <path>
    description: <text>
```

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Type</th>
      <th>Value</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>&lt;template_id&gt;</b></td>
      <td><code>String</code></td>
      <td><b>ID</b></td>
      <td>Unique identifier.</td>
    </tr>
    <tr>
      <td><b>file</b></td>
      <td><code>String</code></td>
      <td><b>Path</b></td>
      <td>Path to the <code>.mustache</code> file.</td>
    </tr>
    <tr>
      <td><b>description</b></td>
      <td><code>String</code></td>
      <td><b>Text</b></td>
      <td>Human-readable description.</td>
    </tr>
  </tbody>
</table>

#### Example

```yaml
templates:
  usecase_template:
    file: 'templates/usecase.mustache'
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