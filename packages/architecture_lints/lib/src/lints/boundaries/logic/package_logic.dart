import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';

mixin PackageLogic {
  /// Checks if the [uri] is an external package (not dart: and not the current project).
  bool isExternalUri(String uri, String currentProjectName) {
    if (uri.startsWith('dart:')) return true;
    if (uri.startsWith('package:')) {
      return !uri.startsWith('package:$currentProjectName/');
    }
    return false;
  }

  /// Checks if [uri] matches any pattern in [patterns].
  bool matchesAnyPattern(String uri, List<String> patterns) {
    for (final pattern in patterns) {
      if (PathMatcher.matches(uri, pattern)) return true;
    }
    return false;
  }

  /// Helper to get the URI string from a NamedType node (Usage check).
  String? getUriFromNode(NamedType node) {
    final element = node.element;
    if (element == null) return null;

    final library = element.library;
    if (library == null) return null;

    return library.firstFragment.source.uri.toString();
  }
}
