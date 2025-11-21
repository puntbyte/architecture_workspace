// lib/src/lints/purity/require_to_entity_method.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/fixes/create_to_entity_method_fix.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class RequireToEntityMethod extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'require_to_entity_method',
    problemMessage: 'The model `{0}` must have a `toEntity()` method that returns its corresponding Entity.',
    correctionMessage: 'Add or correct the `toEntity()` method. Press 💡 for a quick fix.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const RequireToEntityMethod({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  List<Fix> getFixes() => [CreateToEntityMethodFix(config: config)];

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.model) return;

    context.registry.addClassDeclaration((node) {
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      // 1. Find the direct entity supertype.
      // We check the superclass and interfaces to find one that belongs to the Entity layer.
      final entitySupertypeElement = classElement.supertype?.element ??
          classElement.interfaces.firstWhereOrNull((i) {
            final source = i.element.library.firstFragment.source;
            return layerResolver.getComponent(source.fullName) == ArchComponent.entity;
          })?.element;

      // If explicit element check failed, fallback to checking the source of the supertype directly.
      // This handles cases where the element might be resolved but the hierarchy isn't fully traversable yet.
      if (entitySupertypeElement == null) {
        final directSupertypeSource = classElement.supertype?.element.library.firstFragment.source;
        if (directSupertypeSource == null ||
            layerResolver.getComponent(directSupertypeSource.fullName) != ArchComponent.entity) {
          return; // Not an entity subclass
        }
        // If we reach here, the supertype is an entity, so we proceed.
      }

      final toEntityMethod = node.members
          .whereType<MethodDeclaration>()
          .firstWhereOrNull((member) => member.name.lexeme == 'toEntity');

      // 2. If method missing, report on class name.
      if (toEntityMethod == null) {
        reporter.atToken(node.name, _code, arguments: [node.name.lexeme]);
        return;
      }

      // 3. If method exists, validate return type.
      final returnType = toEntityMethod.returnType?.type;
      final expectedElement = entitySupertypeElement ?? classElement.supertype?.element;

      if (returnType?.element != expectedElement) {
        // FIX: Handle reporting separately for Node vs Token to avoid type error.
        if (toEntityMethod.returnType != null) {
          reporter.atNode(toEntityMethod.returnType!, _code, arguments: [node.name.lexeme]);
        } else {
          reporter.atToken(toEntityMethod.name, _code, arguments: [node.name.lexeme]);
        }
      }
    });
  }
}