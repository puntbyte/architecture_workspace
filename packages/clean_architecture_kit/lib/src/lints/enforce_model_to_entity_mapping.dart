// lib/src/lints/enforce_model_to_entity_mapping.dart
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/fixes/create_to_entity_method_fix.dart';
import 'package:clean_architecture_kit/src/utils/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that ensures models have a valid `toEntity()` conversion method.
///
/// It checks any class in a `models` directory that inherits from an Entity
/// to ensure it has a `toEntity()` method with the correct return type.
class EnforceModelToEntityMapping extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_model_to_entity_mapping',
    problemMessage: 'Models must have a `toEntity()` method that returns the correct Entity type.',
    correctionMessage: 'Add or correct the `toEntity()` method.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceModelToEntityMapping({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  List<Fix> getFixes() => [CreateToEntityMethodFix(config: config)];

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.model) return;

    context.registry.addClassDeclaration((node) {
      final entityElement = _findInheritedEntityElement(node);
      if (entityElement == null) return;

      MethodDeclaration? toEntityMethod;
      for (final member in node.members.whereType<MethodDeclaration>()) {
        if (member.name.lexeme == 'toEntity') {
          toEntityMethod = member;
          break;
        }
      }

      // If the method doesn't exist, report the error on the class name.
      if (toEntityMethod == null) {
        reporter.atToken(node.name, _code);
        return;
      }

      // If the method exists, validate its return type.
      final returnType = toEntityMethod.returnType?.type;
      if (returnType == null || returnType.element != entityElement) {
        // The signature is wrong. Report the error on the method itself.
        reporter.atToken(toEntityMethod.name, _code);
      }
    });
  }

  /// Finds the first ClassElement from the extends or implements clauses.
  ClassElement? _findInheritedEntityElement(ClassDeclaration modelNode) {
    final superclass = modelNode.extendsClause?.superclass;
    if (superclass?.element is ClassElement) {
      return superclass!.element! as ClassElement;
    }

    final interface = modelNode.implementsClause?.interfaces.firstOrNull;
    if (interface?.element is ClassElement) {
      return interface!.element! as ClassElement;
    }

    return null;
  }
}
