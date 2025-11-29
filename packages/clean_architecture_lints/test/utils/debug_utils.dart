// test/utils/debug_utils.dart

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/models/configs/architecture_config.dart';

/// Utility to print detailed analyzer state for debugging lint failures.
class DebugUtils {
  static void printAnalysisState(ResolvedUnitResult unit, ArchitectureConfig config) {
    final resolver = LayerResolver(config);
    final component = resolver.getComponent(unit.path);

    print('\n════════════════════ DEBUG STATE ════════════════════');
    print('📂 File: ${unit.path}');
    print('🏛️  Component: $component (Layer: ${component.layer})');
    print('-----------------------------------------------------');

    // Inspect Classes
    for (final decl in unit.unit.declarations.whereType<ClassDeclaration>()) {
      final element = decl.declaredFragment?.element;
      print('📦 Class: ${decl.name.lexeme}');

      if (element == null) {
        print('   ❌ Element is NULL (Resolution Failed)');
        continue;
      }

      print('   🔗 Supertypes:');
      if (element.allSupertypes.isEmpty) {
        print('      (None or Object)');
      }
      for (final type in element.allSupertypes) {
        final name = type.element.name;
        // [Analyzer 8.0.0] access source via fragment
        final uri = type.element.library.firstFragment.source.uri;
        print('      - $name ($uri)');
      }
    }
    print('═════════════════════════════════════════════════════\n');
  }
}
