// lib/src/fixes/create_use_case_fix.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';

// Deliberate import of internal AST locator utility used by many analyzer plugins.
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:clean_architecture_kit/src/utils/path_utils.dart';
import 'package:clean_architecture_kit/src/utils/string_extension.dart';
import 'package:clean_architecture_kit/src/utils/syntax_builder.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_style/dart_style.dart';

/// A private data class to hold the configuration derived from method parameters.
class _UseCaseGenerationConfig {
  /// The base class for the use case (e.g., UnaryUsecase, NullaryUsecase).
  final cb.Reference baseClassName;

  /// The generic types for the base class (e.g., <\OutputType, InputType\>).
  final List<cb.Reference> genericTypes;

  /// The parameters for the `call` method.
  final List<cb.Parameter> callParams;

  /// Positional arguments to pass to the repository method.
  final List<cb.Expression> repoCallPositionalArgs;

  /// Named arguments to pass to the repository method.
  final Map<String, cb.Expression> repoCallNamedArgs;

  /// An optional `TypeDef` for a record, if one is needed.
  final cb.TypeDef? recordTypeDef;

  _UseCaseGenerationConfig({
    required this.baseClassName,
    required this.genericTypes,
    required this.callParams,
    this.repoCallPositionalArgs = const [],
    this.repoCallNamedArgs = const {},
    this.recordTypeDef,
  });
}

class CreateUseCaseFix extends Fix {
  final CleanArchitectureConfig config;

  CreateUseCaseFix({required this.config});

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
      final methodNode = node?.thisOrAncestorOfType<MethodDeclaration>();
      if (methodNode == null) return;
      final repoNode = methodNode.thisOrAncestorOfType<ClassDeclaration>();
      if (repoNode == null) return;

      final useCaseFilePath = PathUtils.getUseCaseFilePath(
        methodName: methodNode.name.lexeme,
        repoPath: diagnostic.problemMessage.filePath,
        config: config,
      );
      if (useCaseFilePath == null) return;

      reporter
          .createChangeBuilder(
            message: 'Create use case for `${methodNode.name.lexeme}`',
            priority: 90,
          )
          .addDartFileEdit(customPath: useCaseFilePath, (builder) {
            _addImports(builder: builder, method: methodNode, repoNode: repoNode);

            // The builder now returns a Library spec directly.
            final library = _buildUseCaseLibrary(method: methodNode, repoNode: repoNode);

            final emitter = cb.DartEmitter(useNullSafetySyntax: true);
            final unformattedCode = library.accept(emitter).toString();
            final formattedCode = DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format(unformattedCode);

            builder.addInsertion(0, (editBuilder) => editBuilder.write(formattedCode));
          });
    });
  }

  /// The main orchestrator method. It's now clean and high-level.
  cb.Library _buildUseCaseLibrary({
    required MethodDeclaration method,
    required ClassDeclaration repoNode,
  }) {
    final bodyElements = <cb.Spec>[];
    final methodName = method.name.lexeme;
    final returnType = cb.refer(method.returnType?.toSource() ?? 'void');
    final outputType = cb.refer(_extractOutputType(returnType.symbol!));

    // 1. Delegate all parameter logic to a dedicated helper.
    final paramConfig = _buildParameterConfig(
      params: method.parameters?.parameters ?? [],
      methodName: methodName,
      outputType: outputType,
    );

    // 2. If the helper created a record, add it to the library.
    if (paramConfig.recordTypeDef != null) {
      bodyElements.add(paramConfig.recordTypeDef!);
    }

    // 3. Gather annotations.
    final annotations = config.services.dependencyInjection.useCaseAnnotations
        .where((a) => a.annotationText.isNotEmpty)
        .map((a) => cb.CodeExpression(cb.Code(a.annotationText)))
        .toList();

    // 4. Determine the final class name.
    final useCaseName = NamingUtils.getExpectedUseCaseClassName(methodName, config);

    // 5. Build the use case class using the configuration.
    bodyElements.addAll(
      SyntaxBuilder.useCase(
        useCaseName: useCaseName,
        repoClassName: repoNode.name.lexeme,
        methodName: methodName,
        returnType: returnType,
        baseClassName: paramConfig.baseClassName,
        genericTypes: paramConfig.genericTypes,
        callParams: paramConfig.callParams,
        repoCallPositionalArgs: paramConfig.repoCallPositionalArgs,
        repoCallNamedArgs: paramConfig.repoCallNamedArgs,
        annotations: annotations,
      ),
    );

    return SyntaxBuilder.library(body: bodyElements);
  }

  /// A dedicated method to handle the logic for 0, 1, or multiple parameters.
  _UseCaseGenerationConfig _buildParameterConfig({
    required List<FormalParameter> params,
    required String methodName,
    required cb.Reference outputType,
  }) {
    // Case 1: No parameters -> NullaryUseCase
    if (params.isEmpty) {
      return _UseCaseGenerationConfig(
        baseClassName: cb.refer(config.inheritance.nullaryUseCaseName),
        genericTypes: [outputType],
        callParams: [],
      );
    }

    // Case 2: One parameter -> UnaryUseCase with a direct type
    if (params.length == 1) {
      final param = params.first;
      final paramType = cb.refer(param.toSource().split(' ').first);
      final paramName = param.name?.lexeme ?? 'param';

      return _UseCaseGenerationConfig(
        baseClassName: cb.refer(config.inheritance.unaryUseCaseName),
        genericTypes: [outputType, paramType],
        callParams: [SyntaxBuilder.parameter(name: paramName, type: paramType)],
        repoCallPositionalArgs: param.isPositional ? [cb.refer(paramName)] : [],
        repoCallNamedArgs: param.isNamed ? {paramName: cb.refer(paramName)} : {},
      );
    }

    // Case 3: Multiple parameters -> UnaryUseCase with a Record
    final useCaseNamePascal = methodName.toPascalCase();
    final recordName = config.naming.useCaseRecordParameter.pattern.replaceAll(
      '{{name}}',
      useCaseNamePascal,
    );
    final recordRef = cb.refer(recordName);

    final namedFields = <String, cb.Reference>{};
    final repoCallNamedArgs = <String, cb.Expression>{};

    for (final p in params) {
      final element = p.declaredFragment?.element;
      if (element == null) continue;
      final displayName = element.displayName;
      namedFields[displayName] = cb.refer(element.type.getDisplayString());
      repoCallNamedArgs[displayName] = cb.refer('params').property(displayName);
    }

    final recordTypeDef = SyntaxBuilder.typeDef(
      name: recordName,
      definition: SyntaxBuilder.recordType(namedFields: namedFields),
    );

    return _UseCaseGenerationConfig(
      baseClassName: cb.refer(config.inheritance.unaryUseCaseName),
      genericTypes: [outputType, recordRef],
      callParams: [SyntaxBuilder.parameter(name: 'params', type: recordRef)],
      repoCallNamedArgs: repoCallNamedArgs,
      recordTypeDef: recordTypeDef,
    );
  }

  void _addImports({
    required DartFileEditBuilder builder,
    required MethodDeclaration method,
    required ClassDeclaration repoNode,
  }) {
    // 1. Use a Set to track URIs that have already been imported.
    final importedUris = <String>{};

    // 2. Create a helper function that checks the Set before importing.
    void importLibraryChecked(Uri uri) {
      final uriString = uri.toString();
      // Only add the import if the URI is not empty and has not been added before.
      if (uriString.isNotEmpty && importedUris.add(uriString)) {
        builder.importLibrary(uri);
      }
    }

    // 3. Use the de-duplicating helper for ALL import operations.
    final repoLibrary = repoNode.declaredFragment?.element.library;
    if (repoLibrary != null) importLibraryChecked(repoLibrary.uri);

    for (final annotation in config.services.dependencyInjection.useCaseAnnotations) {
      if (annotation.importPath.isNotEmpty) importLibraryChecked(Uri.parse(annotation.importPath));
    }

    final unaryPath = config.inheritance.unaryUseCasePath;
    if (unaryPath.isNotEmpty) importLibraryChecked(Uri.parse(unaryPath));

    final nullaryPath = config.inheritance.nullaryUseCasePath;
    if (nullaryPath.isNotEmpty && nullaryPath != unaryPath) {
      importLibraryChecked(Uri.parse(nullaryPath));
    }

    for (final rule in config.typeSafety.returns) {
      if (rule.importPath != null && rule.importPath!.isNotEmpty) {
        importLibraryChecked(Uri.parse(rule.importPath!));
      }
    }

    // 4. Pass the de-duplicating helper down to the recursive type importer.
    for (final param in method.parameters?.parameters ?? <FormalParameter>[]) {
      _importType(param.declaredFragment?.element.type, importLibraryChecked);
    }

    _importType(method.returnType?.type, importLibraryChecked);
  }

  /// The recursive type importer is now simpler. It just calls the provided
  /// `importLibrary` function, which handles the de-duplication logic.
  void _importType(DartType? type, void Function(Uri) importLibrary) {
    if (type == null) return;

    if (type is InterfaceType && type.typeArguments.isNotEmpty) {
      for (final arg in type.typeArguments) {
        _importType(arg, importLibrary);
      }
    } else {
      final library = type.element?.library;
      if (library != null && !library.isInSdk) importLibrary(library.uri);
    }
  }

  String _extractOutputType(String returnTypeSource) {
    final regex = RegExp(r'<.*,\s*([^>]+)>|<([^>]+)>');
    final match = regex.firstMatch(returnTypeSource);

    return match?.group(2)?.trim() ?? match?.group(1)?.trim() ?? 'void';
  }
}
