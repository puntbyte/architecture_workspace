import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class PackagePathResolver {
  // Cache: ProjectRoot -> { PackageName : AbsoluteLibPath }
  static final Map<String, Map<String, String>> _cache = {};

  /// Resolves 'package:foo/config.yaml' to an absolute file path.
  static Future<String?> resolve({
    required String packageUri,
    required String projectRoot,
  }) async {
    if (!packageUri.startsWith('package:')) return null;

    // 1. Parse URI parts (e.g. 'package:foo/config.yaml')
    // package name: 'foo'
    // relative path: 'config.yaml'
    final uriContent = packageUri.substring(8); // remove 'package:'
    final slashIndex = uriContent.indexOf('/');
    if (slashIndex == -1) return null;

    final packageName = uriContent.substring(0, slashIndex);
    final relativePath = uriContent.substring(slashIndex + 1);

    // 2. Get Package Map for this project
    final packageMap = await _getPackageMap(projectRoot);
    if (packageMap == null) return null;

    final packageLibPath = packageMap[packageName];
    if (packageLibPath == null) return null;

    // 3. Join path
    return p.normalize(p.join(packageLibPath, relativePath));
  }

  /// Parses .dart_tool/package_config.json
  static Future<Map<String, String>?> _getPackageMap(String projectRoot) async {
    if (_cache.containsKey(projectRoot)) return _cache[projectRoot];

    final configPath = p.join(projectRoot, '.dart_tool', 'package_config.json');
    final file = File(configPath);

    if (!file.existsSync()) return null;

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final packages = json['packages'] as List<dynamic>;

      final map = <String, String>{};
      final configDir = p.dirname(configPath); // .../.dart_tool

      for (final pkg in packages) {
        final name = pkg['name'] as String;
        final rootUri = pkg['rootUri'] as String;
        final packageUri = pkg['packageUri'] as String; // usually 'lib/'

        String absoluteRoot;

        // Handle absolute file URIs vs relative paths
        if (rootUri.startsWith('file://')) {
          absoluteRoot = Uri.parse(rootUri).toFilePath();
        } else {
          // Relative to .dart_tool/package_config.json
          absoluteRoot = p.join(configDir, rootUri);
        }

        // Combine root + packageUri to get the 'package:name/' base path
        final absoluteLib = p.join(absoluteRoot, packageUri);
        map[name] = p.normalize(absoluteLib);
      }

      _cache[projectRoot] = map;
      return map;
    } catch (e) {
      // Fail silently if config is malformed
      return null;
    }
  }
}