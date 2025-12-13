import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/node_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/parameter_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';

class ImportExtractor {
  final String packageName;

  const ImportExtractor(this.packageName);

  void extract(dynamic value, Set<String> imports) {
    if (value == null) return;

    if (value is String) {
      _addPathOrUri(value, imports);
    } else if (value is Definition) {
      if (value.import != null) _addPathOrUri(value.import!, imports);
      for (final i in value.imports) {
        _addPathOrUri(i, imports);
      }
    } else if (value is TypeWrapper) {
      // 1. Add the type's own import (Class or Typedef)
      if (value.importUri.isNotEmpty) _addPathOrUri(value.importUri.value, imports);

      final type = value.type;
      if (type != null) {
        // 2. Handle Typedefs (Alias)
        // If it's an alias (e.g. FutureEither<User>), we only care about the alias arguments (User).
        // We do NOT want to recurse into the underlying type (Future<Either<Failure, User>>),
        // because those internal types (Either, Failure) are implementation details of the typedef.
        if (type.alias != null) {
          for (final arg in type.alias!.typeArguments) {
            extract(TypeWrapper(arg), imports);
          }
        }
        // 3. Handle Standard Interface Types
        else if (type is InterfaceType) {
          for (final arg in type.typeArguments) {
            extract(TypeWrapper(arg), imports);
          }
        }
      }
    } else if (value is NodeWrapper) {
      if (value.filePath.isNotEmpty) _addPathOrUri(value.filePath.value, imports);
    } else if (value is Iterable) {
      for (final item in value) {
        extract(item, imports);
      }
    } else if (value is ListWrapper) {
      for (var i = 0; i < value.length; i++) {
        extract(value[i], imports);
      }
    } else if (value is ParameterWrapper) {
      extract(value.type, imports);
    } else if (value is Map && value.containsKey('import')) {
      _addPathOrUri(value['import'].toString(), imports);
    }
  }

  void _addPathOrUri(String uriOrPath, Set<String> imports) {
    if (uriOrPath.isEmpty || uriOrPath == 'dart:core') return;
    if (uriOrPath == 'dynamic' || uriOrPath == 'void') return;

    var uri = uriOrPath;

    // Normalize deep imports
    if (uri.startsWith('package:fpdart/src/')) {
      uri = 'package:fpdart/fpdart.dart';
    }

    // 1. Already a URI?
    if (uri.startsWith('package:') || uri.startsWith('dart:')) {
      imports.add(uri);
      return;
    }

    // 2. Absolute Path -> Package URI
    // Robust normalization for Windows/Unix paths
    final normalized = uri.replaceAll(r'\', '/');
    if (normalized.contains('/lib/')) {
      final parts = normalized.split('/lib/');
      // parts.last contains the path after lib/ (e.g. features/auth/domain/ports/auth_port.dart)
      final relative = parts.last;
      imports.add('package:$packageName/$relative');
      return;
    }
  }
}
