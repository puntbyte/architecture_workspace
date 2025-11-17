// lib/src/analysis/arch_component.dart

/// Represents the specific architectural component a file or class corresponds to.
///
/// The `snake_case` names of these enum values are the source of truth for keys
/// in the `analysis_options.yaml` configuration (e.g., `on: 'use_case'`).
enum ArchComponent {
  // --- Domain Components ---
  entity('entity', 'Entity'),
  contract('contract', 'Repository Interface'),
  usecase('usecase', 'Use Case'),
  usecaseParameter('usecase.parameter', 'Use Case Parameter'),

  // --- Data Components ---
  model('model', 'Model'),
  repository('repository.implementation', 'Repository Implementation'),
  source('source.interface', 'Data Source Interface'),
  sourceImplementation('source.implementation', 'Data Source Implementation'),

  // --- Presentation Components ---
  page('page', 'Page'),
  widget('widget', 'Widget'),
  manager('manager', 'Manager'),

  event('event.interface', 'Event'),
  eventImplementation('event.implementation', 'Event Implementation'),
  state('state.interface', 'State'),
  stateImplementation('state.implementation', 'State Implementation'),
  unknown('unknown', 'Unknown');

  /// The `snake_case` identifier used in `analysis_options.yaml`.
  final String id;

  /// A user-friendly label for error messages.
  final String label;

  const ArchComponent(this.id, this.label);

  /// A reverse lookup to find an enum value from its string [id].
  static ArchComponent fromId(String id) {
    return values.firstWhere((value) => value.id == id, orElse: () => ArchComponent.unknown);
  }

  // --- Layer Composition Getters ---

  /// Returns a set of all components that belong to the Domain Layer.
  static Set<ArchComponent> get domainLayer => {
    entity,
    contract,
    usecase,
  };

  /// Returns a set of all components that belong to the Data Layer.
  static Set<ArchComponent> get dataLayer => {
    model,
    repository,
    source,
    sourceImplementation,
  };

  /// Returns a set of all components that belong to the Presentation Layer.
  static Set<ArchComponent> get presentationLayer => {
    page,
    widget,
    manager,
    event,
    eventImplementation,
    state,
    stateImplementation,
  };
}
