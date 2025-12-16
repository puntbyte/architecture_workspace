// lib/src/config/schema/architecture_config.dart

import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/definitions/action_definition.dart';
import 'package:architecture_lints/src/schema/policies/annotation_policy.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:architecture_lints/src/schema/policies/dependency_policy.dart';
import 'package:architecture_lints/src/schema/policies/exception_policy.dart';
import 'package:architecture_lints/src/schema/policies/inheritance_policy.dart';
import 'package:architecture_lints/src/schema/policies/member_policy.dart';
import 'package:architecture_lints/src/schema/definitions/module_definition.dart';
import 'package:architecture_lints/src/schema/policies/relationship_policy.dart';
import 'package:architecture_lints/src/schema/definitions/template_definition.dart';
import 'package:architecture_lints/src/schema/policies/type_safety_policy.dart';
import 'package:architecture_lints/src/schema/policies/usage_policy.dart';
import 'package:architecture_lints/src/schema/definitions/vocabulary_definition.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';

class ArchitectureConfig {
  final String? filePath;

  final List<ModuleDefinition> modules;
  final List<ComponentDefinition> components;
  final Map<String, TypeDefinition> definitions;

  final List<DependencyPolicy> dependencies;
  final List<InheritancePolicy> inheritances;
  final List<TypeSafetyPolicy> typeSafeties;
  final List<ExceptionPolicy> exceptions;
  final List<MemberPolicy> members;
  final List<UsagePolicy> usages;
  final List<AnnotationPolicy> annotations;
  final List<RelationshipPolicy> relationships;

  final List<ActionDefinition> actions;
  final Map<String, TemplateDefinition> templates;

  final List<String> excludes;
  final VocabularyDefinition vocabulary;

  const ArchitectureConfig({
    required this.components,
    this.modules = const [],
    this.definitions = const {},

    this.dependencies = const [],
    this.inheritances = const [],
    this.typeSafeties = const [],
    this.exceptions = const [],
    this.members = const [],
    this.usages = const [],
    this.annotations = const [],
    this.relationships = const [],

    this.actions = const [],
    this.templates = const {},

    this.excludes = const [],
    this.vocabulary = const VocabularyDefinition(),

    this.filePath,
  });

  factory ArchitectureConfig.empty() => const ArchitectureConfig(components: []);

  factory ArchitectureConfig.fromYaml(Map<dynamic, dynamic> yaml, {String? filePath}) {
    // Modules
    final modules = ModuleDefinition.parseMap(yaml.mustGetMap(ConfigKeys.root.modules));

    return ArchitectureConfig(
      filePath: filePath,
      modules: modules,
      components: ComponentDefinition.parseMap(yaml.mustGetMap(ConfigKeys.root.components), modules),
      definitions: TypeDefinition.parseRegistry(yaml.mustGetMap(ConfigKeys.root.definitions)),

      dependencies: DependencyPolicy.parseList(yaml.mustGetMapList(ConfigKeys.root.dependencies)),
      inheritances: InheritancePolicy.parseList(yaml.mustGetMapList(ConfigKeys.root.inheritances)),
      typeSafeties: TypeSafetyPolicy.parseList(yaml.mustGetMapList(ConfigKeys.root.typeSafeties)),
      exceptions: ExceptionPolicy.parseList(yaml.mustGetMapList(ConfigKeys.root.exceptions)),
      members: MemberPolicy.parseList(yaml.mustGetMapList(ConfigKeys.root.members)),
      usages: UsagePolicy.parseList(yaml.mustGetMapList(ConfigKeys.root.usages)),
      annotations: AnnotationPolicy.parseList(yaml.mustGetMapList(ConfigKeys.root.annotations)),
      relationships: RelationshipPolicy.parseList(
        yaml.mustGetMapList(ConfigKeys.root.relationships),
      ),

      actions: ActionDefinition.parseMap(yaml.mustGetMap('actions')),
      templates: yaml
          .mustGetMap(ConfigKeys.root.templates)
          .map((key, value) => MapEntry(key, TemplateDefinition.fromDynamic(value))),

      excludes: yaml.mustGetStringList(ConfigKeys.root.excludes),
      vocabulary: VocabularyDefinition.fromMap(yaml.getMap(ConfigKeys.root.vocabularies)),
    );
  }

  /// Helper to find actions for a specific error code
  List<ActionDefinition> getActionsForError(String errorCode) =>
      actions.where((a) => a.trigger.errorCode == errorCode).toList();

  Map<String, String> get importRewrites {
    final rewrites = <String, String>{};

    for (final def in definitions.values) {
      // Only rewrite if we have a target import (the public one)
      if (def.import != null && def.rewrites.isNotEmpty) {
        for (final badPath in def.rewrites) {
          rewrites[badPath] = def.import!;
        }
      }
    }

    return rewrites;
  }
}
