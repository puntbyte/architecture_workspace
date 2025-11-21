import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

class CreateToEntityMappingFix extends Fix {
  final CleanArchitectureConfig config;
  CreateToEntityMappingFix({required this.config});

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
      // Locate the Model class declaration that the lint was reported on.
      final locator = NodeLocator2(diagnostic.problemMessage.offset);
      final modelNode = locator.searchWithin(resolvedUnit.unit)?.thisOrAncestorOfType<ClassDeclaration>();
      if (modelNode == null) return;

      final modelName = modelNode.name.lexeme;

      // Use the naming convention to infer the Entity's name.
      final modelTemplate = config.naming.model;
      final entityTemplate = config.naming.entity;
      final baseName = _extractBaseName(modelName, modelTemplate) ?? modelName;
      final entityName = entityTemplate.replaceAll('{{name}}', baseName);

      // Create a unique, descriptive message for the fix.
      final changeBuilder = reporter.createChangeBuilder(
        message: 'Create `toEntity()` extension for `$modelName`',
        priority: 80, // A slightly lower priority than UseCase creation.
      );

      // We will create the extension in a new file to keep things clean.
      final originalFilePath = resolvedUnit.path;
      final newFileName = '${p.basenameWithoutExtension(originalFilePath)}_mapping.dart';
      final newFilePath = p.join(p.dirname(originalFilePath), newFileName);

      changeBuilder.addDartFileEdit(customPath: newFilePath, (builder) {
        // Build the AST for the extension file.
        final library = _buildMappingLibrary(
          modelName: modelName,
          entityName: entityName,
          originalModelFileName: p.basename(originalFilePath),
        );

        // Format and write the generated code.
        final emitter = cb.DartEmitter(useNullSafetySyntax: true);
        final unformattedCode = library.accept(emitter).toString();
        final formattedCode = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format(unformattedCode);
        builder.addInsertion(0, (editBuilder) => editBuilder.write(formattedCode));
      });
    });
  }

  /// Extracts the base name from a class name based on a template.
  /// Example: 'UserModel' with '{{name}}Model' -> 'User'
  String? _extractBaseName(String name, String template) {
    final pattern = template.replaceAll('{{name}}', '([A-Z][a-zA-Z0-9]+)');
    final regex = RegExp('^$pattern\$');
    final match = regex.firstMatch(name);
    return match?.group(1);
  }

  /// Builds the complete library for the new mapping file.
  cb.Library _buildMappingLibrary({
    required String modelName,
    required String entityName,
    required String originalModelFileName,
  }) {
    final extension = cb.Extension(
          (b) => b
        ..name = '${modelName}Mapping'
        ..on = cb.refer(modelName)
        ..methods.add(
          cb.Method(
                (m) => m
              ..name = 'toEntity'
              ..returns = cb.refer(entityName)
            // This is a basic mapping. It assumes the fields are the same.
            // Users will need to adjust this for more complex mappings.
              ..body = cb.Code('''
                return $entityName(
                  // TODO: Implement the mapping from $modelName to $entityName.
                  // Example: id: id, name: name,
                );
              '''),
          ),
        ),
    );

    return cb.Library(
          (b) => b
      // Import the original model file.
        ..directives.add(cb.Directive.import(originalModelFileName))
      // TODO: You may need to add logic here to find and import the entity file.
      // For now, we assume it's available or the user will add the import.
        ..body.add(extension),
    );
  }
}
