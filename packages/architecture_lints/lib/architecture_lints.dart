// lib/src/architecture_lints_plugin.dart

import 'package:architecture_lints/src/lints/boundaries/rules/external_dependency_rule.dart';
import 'package:architecture_lints/src/lints/boundaries/rules/layer_dependency_rule.dart';
import 'package:architecture_lints/src/lints/consistency/rules/orphan_file_rule.dart';
import 'package:architecture_lints/src/lints/identity/rules/inheritance_allowed_rule.dart';
import 'package:architecture_lints/src/lints/identity/rules/inheritance_forbidden_rule.dart';
import 'package:architecture_lints/src/lints/identity/rules/inheritance_required_rule.dart';
import 'package:architecture_lints/src/lints/naming/rules/naming_antipattern_rule.dart';
import 'package:architecture_lints/src/lints/naming/rules/naming_pattern_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Entry point for custom_lint
PluginBase createPlugin() => _ArchitectureLintsPlugin();

class _ArchitectureLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      const OrphanFileRule(),

      const NamingPatternRule(),
      const NamingAntipatternRule(),

      const LayerDependencyRule(),
      const ExternalDependencyRule(),

      const InheritanceRequiredRule(),
      const InheritanceAllowedRule(),
      const InheritanceForbiddenRule(),
    ];
  }
}
