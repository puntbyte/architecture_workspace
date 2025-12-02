import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/lints/architecture_lint.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

class ProjectStructureLint extends ArchitectureLint {
  static const LintCode _code = LintCode(
    name: 'arch_orphan_file',
    problemMessage: 'This file does not belong to any defined architectural component.',
    correctionMessage: 'Move this file to a directory defined in architecture.yaml.',
  );

  const ProjectStructureLint() : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      final config = getConfig();

      // If config failed to parse, we can't enforce rules, so we return.
      if (config == null) return;

      final path = resolver.path;

      // 1. Filter exclusions
      if (!path.contains('lib')) return;
      if (path.endsWith('.g.dart')) return;
      if (path.endsWith('.freezed.dart')) return;
      if (p.basename(path) == 'main.dart') return;

      // 2. Check Architecture
      final component = getComponentFromFile(config, path);

      // 3. Report Error if Orphan
      if (component == null) {
        reporter.atNode(node, code);
      }
    });
  }
}
