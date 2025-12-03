import 'package:analyzer/dart/ast/ast.dart';

class ImportResolver {
  /// Resolves the absolute file path of an import directive using the Analysis Element.
  /// Returns null if the import cannot be resolved (e.g., syntax error, missing file, or dart: import).
  static String? resolvePath({required ImportDirective node}) {
    // 1. Check if the URI is a 'dart:' import (we don't lint internal dart libs file paths)
    final uriString = node.uri.stringValue;
    if (uriString != null && uriString.startsWith('dart:')) {
      return null;
    }

    // 2. Get the library import element
    final libraryImport = node.libraryImport;
    if (libraryImport == null) return null;

    final importedLibrary = libraryImport.importedLibrary;
    if (importedLibrary == null) return null;

    // 3. Get the source from the FIRST fragment of the library.
    final source = importedLibrary.firstFragment.source;

    // 4. Check URI Scheme instead of UriKind
    // We only care about 'file:' (local files) and 'package:' (dependencies)
    final uri = source.uri;
    if (!uri.isScheme('file') && !uri.isScheme('package')) {
      return null;
    }

    // fullName typically returns the absolute path on disk for these schemes
    return source.fullName;
  }
}
