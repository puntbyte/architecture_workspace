import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';

//
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/syntax_builder.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_style/dart_style.dart';

class CreateToEntityMethodFix extends Fix {
  final CleanArchitectureConfig config;

  CreateToEntityMethodFix({required this.config});

  @override
  List<String> get filesToAnalyze => const ['**.dart'];

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.addPostRunCallback(() async {
      final resolvedUnit = await resolver.getResolvedUnitResult();
      final locator = NodeLocator2(diagnostic.problemMessage.offset);
      final node = locator.searchWithin(resolvedUnit.unit);

      final modelNode = node?.thisOrAncestorOfType<ClassDeclaration>();
      if (modelNode == null) return;

      final entityElement = _findInheritedEntityElement(modelNode);
      if (entityElement == null) return;

      final entityName = entityElement.name;
      if (entityName == null) return;

      final modelName = modelNode.name.lexeme;

      // 1. First, determine if a `toEntity` method already exists.
      MethodDeclaration? existingMethod;
      for (final member in modelNode.members.whereType<MethodDeclaration>()) {
        if (member.name.lexeme == 'toEntity') {
          existingMethod = member;
          break;
        }
      }

      // 2. Choose the message and indent level based on whether the method exists.
      final isCorrection = existingMethod != null;
      final message = isCorrection
          ? 'Correct `toEntity()` method signature in `$modelName`'
          : 'Create `toEntity()` method in `$modelName`';

      // 3. Create the change builder with the specific message.
      reporter
          .createChangeBuilder(
            message: message,
            priority: 90,
          )
          .addDartFileEdit((builder) {
            final method = _buildToEntityMethod(
              modelNode: modelNode,
              entityElement: entityElement,
              entityName: entityName, // Pass the now non-null name
            );

            final emitter = cb.DartEmitter(useNullSafetySyntax: true);
            final unformattedCode = method.accept(emitter).toString();

            // FIX #2: Add required `languageVersion`.
            final formatter = DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
              indent: 2,
            );

            final formattedCode = formatter.format(unformattedCode);

            if (existingMethod != null) {
              // 2. For replacements, the existing node's position provides the
              //    base indent. We remove the first level of indent from our
              //    formatted block to prevent it from being applied twice.
              final codeForReplacement = formattedCode.startsWith('  ')
                  ? formattedCode.substring(2)
                  : formattedCode;

              builder.addReplacement(
                SourceRange(existingMethod.offset, existingMethod.length),
                (editBuilder) => editBuilder.write(codeForReplacement),
              );
            } else {
              // 3. For insertions, we need the fully indented block, plus a newline.
              final insertionOffset = modelNode.rightBracket.offset;
              builder.addInsertion(
                insertionOffset,
                (editBuilder) => editBuilder
                  ..write('\n')
                  ..write(formattedCode),
              );
            }
          });
    });
  }

  ClassElement? _findInheritedEntityElement(ClassDeclaration modelNode) {
    final superclass = modelNode.extendsClause?.superclass;
    if (superclass?.element is ClassElement) return superclass!.element! as ClassElement;
    final interface = modelNode.implementsClause?.interfaces.firstOrNull;
    if (interface?.element is ClassElement) return interface!.element! as ClassElement;
    return null;
  }

  cb.Method _buildToEntityMethod({
    required ClassDeclaration modelNode,
    required ClassElement entityElement,
    required String entityName, // Now non-nullable
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
      // FIX #4: Use `formalParameters` instead of `parameters`.
      for (final param in constructor.formalParameters) {
        // FIX #5: Guard against null parameter names.
        final paramName = param.name;
        if (paramName == null) continue;

        final mapping = modelFieldNames.contains(paramName)
            ? cb.refer(paramName)
            : cb.refer("throw UnimplementedError('TODO: Implement mapping for \"$paramName\"')");

        if (param.isNamed) {
          namedArgs[paramName] = mapping;
        } else if (param.isPositional) {
          positionalArgs.add(mapping);
        }
      }
    }

    final body = SyntaxBuilder.call(
      cb.refer(entityName), // Now safe
      positional: positionalArgs,
      named: namedArgs,
    ).returned.statement;

    return SyntaxBuilder.method(
      name: 'toEntity',
      returns: cb.refer(entityName), // Now safe
      body: body,
    );
  }
}
