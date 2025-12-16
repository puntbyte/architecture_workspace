// lib/src/schema/enums/action_scope.dart

enum ActionScope {
  /// The file/node where the error occurred.
  current,

  /// A file related to the current one based on architecture rules.
  related
  ;

  static ActionScope fromKey(String? key) =>
      ActionScope.values.firstWhere((scope) => scope.name == key, orElse: () => current);
}
