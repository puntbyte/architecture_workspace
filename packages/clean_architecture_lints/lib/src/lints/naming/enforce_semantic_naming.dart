// lib/src/lints/naming/enforce_semantic_naming.dart

import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/natural_language_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes follow the semantic naming conventions (`grammar`).
class EnforceSemanticNaming extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_semantic_naming',
    problemMessage: 'The name `{0}` does not follow the grammatical structure `{1}` for a {2}.',
  );

  final NaturalLanguageUtils nlpUtils;

  const EnforceSemanticNaming({
    required super.config,
    required super.layerResolver,
    required this.nlpUtils,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;

      // 1. Identify component
      final component = layerResolver.getComponent(resolver.source.fullName, className: className);
      if (component == ArchComponent.unknown) return;

      // 2. Get Rule
      final rule = config.namingConventions.getRuleFor(component);
      final grammar = rule?.grammar;
      if (grammar == null || grammar.isEmpty) return;

      // 3. Validate
      final validator = _GrammarValidator(grammar, nlpUtils);
      if (!validator.isValid(className)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [className, grammar, component.label],
        );
      }
    });
  }
}

/// A private helper class for parsing and validating a grammar pattern.
class _GrammarValidator {
  final String grammar;
  final NaturalLanguageUtils nlp;

  _GrammarValidator(this.grammar, this.nlp);

  bool isValid(String className) {
    final words = className.splitPascalCase();
    if (words.isEmpty) return false;

    // --- Heuristic-based Grammar Parsing ---

    // Case 1: {{verb.present}}{{noun.phrase}} (e.g., Usecases)
    // Example: "GetUser", "LoginUser"
    if (grammar == '{{verb.present}}{{noun.phrase}}') {
      if (words.length < 2) return false;
      // First word must be a verb (e.g. Get, Save)
      // Last word must be a noun (e.g. User, Data)
      return nlp.isVerb(words.first) && nlp.isNoun(words.last);
    }

    // Case 2: {{noun.phrase}} (with optional suffix)
    // Examples: "User" (Entity), "UserModel" (Model)
    if (grammar.startsWith('{{noun.phrase}}')) {
      final suffix = grammar.substring('{{noun.phrase}}'.length);

      // Check strict suffix match if present
      if (suffix.isNotEmpty && !className.endsWith(suffix)) return false;

      final baseName = suffix.isNotEmpty
          ? className.substring(0, className.length - suffix.length)
          : className;

      final baseWords = baseName.splitPascalCase();
      if (baseWords.isEmpty) return false;

      // A noun phrase:
      // 1. Should end with a noun (The subject).
      final endsWithNoun = nlp.isNoun(baseWords.last);

      // 2. Should NOT contain verbs or gerunds (actions).
      // "FetchingUser" -> "Fetching" is a gerund -> Invalid.
      // "GetUser" -> "Get" is a verb -> Invalid.
      final containsNoVerbs = !baseWords.any((w) => nlp.isVerb(w) || nlp.isVerbGerund(w));

      return endsWithNoun && containsNoVerbs;
    }

    // Case 3: {{subject}}({{adjective}}|{{verb.gerund}}|{{verb.past}}) (e.g., States)
    // Examples: "AuthLoading", "AuthLoaded", "AuthInitial"
    if (grammar.contains('{{adjective}}|{{verb.gerund}}|{{verb.past}}')) {
      if (words.length < 2) return false;
      final lastWord = words.last;
      // The last word describes the state of the subject
      return nlp.isAdjective(lastWord) || nlp.isVerbGerund(lastWord) || nlp.isVerbPast(lastWord);
    }

    // Default to true if the grammar is not yet supported by our heuristics.
    return true;
  }
}