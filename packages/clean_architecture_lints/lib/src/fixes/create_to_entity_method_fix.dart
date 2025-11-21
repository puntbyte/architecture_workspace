import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/syntax_builder.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

/// A quick fix that generates or corrects the `toEntity()` method in a Model class.
class CreateToEntityMethodFix extends DartFix {
  final ArchitectureConfig config;

  CreateToEntityMethodFix({required this.config});

  static final _unitResultKey = Object();

  @override
  Future<void> startUp(CustomLintResolver resolver, CustomLintContext context) async {
    if (!context.sharedState.containsKey(_unitResultKey)) {
      context.sharedState[_unitResultKey] = await resolver.getResolvedUnitResult();
    }
  }

  @override
  void run(
      CustomLintResolver resolver,
      ChangeReporter reporter,
      CustomLintContext context,
      Diagnostic diagnostic,
      List<Diagnostic> others,
      ) {
    final resolvedUnit = context.sharedState[_unitResultKey] as ResolvedUnitResult?;
    if (resolvedUnit == null) return;

    final node = NodeLocator2(diagnostic.offset).searchWithin(resolvedUnit.unit);
    final modelNode = node?.thisOrAncestorOfType<ClassDeclaration>();
    if (modelNode == null) return;

    // FIX: Use declaredElement for better API compatibility
    final classElement = modelNode.declaredFragment?.element;

    final layerResolver = LayerResolver(config);
    final entitySupertype = classElement?.allSupertypes.firstWhereOrNull((st) {
      // FIX: Add null safety for library and source access
      final library = st.element.library;

      final source = library.firstFragment.source;

      final component = layerResolver.getComponent(source.fullName);
      return component == ArchComponent.entity;
    });

    if (entitySupertype == null) return;

    final entityElement = entitySupertype.element;
    if (entityElement is! ClassElement) return;

    // FIX: name is non-nullable in recent analyzer versions
    final entityName = entityElement.name;
    if (entityName!.isEmpty) return;

    final modelName = modelNode.name.lexeme;
    final existingMethod = modelNode.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull((m) => m.name.lexeme == 'toEntity');

    final message = existingMethod != null
        ? 'Correct `toEntity()` method in `$modelName`'
        : 'Create `toEntity()` method in `$modelName`';

    reporter.createChangeBuilder(message: message, priority: 90).addDartFileEdit((builder) {
      final method = _buildToEntityMethod(
        modelNode: modelNode,
        entityElement: entityElement,
        entityName: entityName,
      );
      final emitter = cb.DartEmitter(useNullSafetySyntax: true);
      final formattedBlock = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(method.accept(emitter).toString());

      if (existingMethod != null) {
        builder.addReplacement(
          SourceRange(existingMethod.offset, existingMethod.length),
              (editBuilder) => editBuilder.write(formattedBlock),
        );
      } else {
        final insertionOffset = modelNode.rightBracket.offset;
        builder.addInsertion(
          insertionOffset,
              (editBuilder) => editBuilder.write('\n\n  $formattedBlock'),
        );
      }
    });
  }

  cb.Method _buildToEntityMethod({
    required ClassDeclaration modelNode,
    required ClassElement entityElement,
    required String entityName,
  }) {
    final modelFieldNames = modelNode.members
        .whereType<FieldDeclaration>()
        .expand((f) => f.fields.variables)
        .map((v) => v.name.lexeme)
        .toSet();

    final positionalArgs = <cb.Expression>[];
    final namedArgs = <String, cb.Expression>{};
    final constructor = entityElement.unnamedConstructor;

    if (constructor != null) {
      // FIX: Use parameters instead of formalParameters
      for (final param in constructor.formalParameters) {
        final paramName = param.name;
        if (paramName!.isEmpty) continue;

        final mapping = modelFieldNames.contains(paramName)
            ? cb.refer(paramName!)
            : cb.refer("throw UnimplementedError('TODO: Map field \"$paramName\"')");

        if (param.isNamed) {
          namedArgs[paramName!] = mapping;
        } else if (param.isPositional || param.isRequiredPositional) {
          positionalArgs.add(mapping);
        }
      }
    }

    final body = SyntaxBuilder.call(
      cb.refer(entityName),
      positional: positionalArgs,
      named: namedArgs,
    ).returned.statement;

    return SyntaxBuilder.method(
      name: 'toEntity',
      returns: cb.refer(entityName),
      body: body,
      annotations: [cb.refer('override')],
    );
  }
}
