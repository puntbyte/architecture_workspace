// lib/src/lints/structure/enforce_model_to_entity_mapping.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/fixes/create_to_entity_method_fix.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that ensures models have a valid `toEntity()` conversion method.
///
/// **Reasoning:** The boundary between the Data and Domain layers is the Repository,
/// which is responsible for mapping data Models to domain Entities. To make this
/// possible, every Model that corresponds to an Entity must provide a `toEntity()`
/// conversion method that returns the correct Entity type. This lint enforces that contract.
class EnforceModelToEntityMapping extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_model_to_entity_mapping',
    problemMessage: 'Models must have a `toEntity()` method that returns the correct Entity type.',
    correctionMessage: 'Add or correct the `toEntity()` method. Press 💡 for a quick fix.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceModelToEntityMapping({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  /// Provides the quick fix to generate the method.
  @override
  List<Fix> getFixes() => [CreateToEntityMethodFix(config: config)];

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.model) return;

    context.registry.addClassDeclaration((node) {
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      // 1. Find the corresponding Entity that this Model inherits from.
      final entitySupertype = classElement.allSupertypes.firstWhereOrNull((supertype) {
        final source = supertype.element.firstFragment.libraryFragment.source;
        return layerResolver.getComponent(source.fullName) == ArchComponent.entity;
      });

      if (entitySupertype == null) return; // This is not a model that inherits from an entity.

      // 2. Search for an existing `toEntity` method in the class declaration.
      final toEntityMethod = node.members.whereType<MethodDeclaration>().firstWhereOrNull(
        (member) => member.name.lexeme == 'toEntity',
      );

      // 3. If the method doesn't exist, report the error on the class name.
      if (toEntityMethod == null) {
        reporter.atToken(node.name, _code);
        return;
      }

      // 4. If the method exists, validate its return type.
      // The return type must match the Entity it inherited from.
      final returnType = toEntityMethod.returnType?.type;
      if (returnType == null || returnType.element != entitySupertype.element) {
        // The signature is wrong. Report the error on the method itself.
        reporter.atToken(toEntityMethod.name, _code);
      }
    });
  }
}
