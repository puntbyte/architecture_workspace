import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:architecture_lints/src/engines/expression/expression.dart';

class ImportExtractor {
  final String packageName;
  final Map<String, String> rewrites;

  const ImportExtractor(
    this.packageName, {
    this.rewrites = const {},
  });

  void extract(dynamic value, Set<String> imports) {
    if (value == null) return;

    if (value is String) {
      _addPathOrUri(value, imports);
    } else if (value is StringWrapper) {
      _addPathOrUri(value.value, imports);
    } else if (value is Definition) {
      if (value.import != null) _addPathOrUri(value.import!, imports);
      for (final i in value.imports) {
        _addPathOrUri(i, imports);
      }
    } else if (value is TypeWrapper) {
      if (value.importUri.isNotEmpty) _addPathOrUri(value.importUri.value, imports);

      final type = value.type;
      if (type != null) {
        if (type.alias != null) {
          for (final arg in type.alias!.typeArguments) {
            extract(TypeWrapper(arg), imports);
          }
        } else if (type is InterfaceType) {
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

    for (final entry in rewrites.entries) {
      if (uri.startsWith(entry.key)) {
        uri = entry.value;
        break;
      }
    }

    // 1. Already a Package/Dart URI?
    if (uri.startsWith('package:') || uri.startsWith('dart:')) {
      imports.add(uri);
      return;
    }

    // 2. Normalize File Path to Package URI
    final normalized = uri.replaceAll(r'\', '/');
    if (normalized.contains('/lib/')) {
      final parts = normalized.split('/lib/');
      final relative = parts.last;
      imports.add('package:$packageName/$relative');
      return;
    }
  }
}
