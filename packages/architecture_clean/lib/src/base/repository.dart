/// {@template repository}
/// Base class for all repositories.
///
/// This class is used by the `enforce_repository_inheritance` lint to ensure that all repository
/// classes inherit from it.
/// {@endtemplate}
abstract interface class Repository {
  /// {@macro repository}
  const Repository();
}
