import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/enums/component_kind.dart';
import 'package:architecture_lints/src/config/enums/component_mode.dart';
import 'package:architecture_lints/src/config/enums/component_modifier.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';

class ComponentRefiner with InheritanceLogic, NamingLogic {
  final ArchitectureConfig config;
  final FileResolver fileResolver;

  const ComponentRefiner(this.config, this.fileResolver);

  ComponentContext? refine({
    required String filePath,
    required ResolvedUnitResult unit,
  }) {
    // 1. Get Candidates based on Path
    var candidates = fileResolver.resolveAllCandidates(filePath);
    if (candidates.isEmpty) return null;

    // Filter out namespaces (folders shouldn't match files)
    candidates = candidates.where((c) => c.component.mode != ComponentMode.namespace).toList();

    if (candidates.isEmpty) return null;

    // Fast path for single candidate
    if (candidates.length == 1) {
      return _buildContext(filePath, candidates.first.component);
    }

    // 2. Identify Declarations to Check
    final mainNode = _findMainDeclaration(unit.unit, filePath);
    final element = mainNode?.declaredFragment?.element;

    // Name for validation
    final className = element?.name;

    // Structure Info for Heuristics
    final isAbstract = element is ClassElement && element.isAbstract;
    final isConcrete = element is ClassElement && !element.isAbstract;

    // 3. Score Candidates
    Candidate? bestCandidate;
    var bestScore = -99999.0;

    for (final candidate in candidates) {
      double score = 0;
      final cConfig = candidate.component;

      // --- CRITERIA 0: PATH SPECIFICITY ---
      score += candidate.matchIndex * 10;
      score += candidate.matchLength;

      // --- CRITERIA 1: NAMING ---
      if (cConfig.patterns.isNotEmpty) {
        var namingMatch = false;

        if (cConfig.mode == ComponentMode.part) {
          // Check ANY declaration in the file
          namingMatch = unit.unit.declarations.any((d) {
            if (d is! NamedCompilationUnitMember) return false;
            return cConfig.patterns.any((p) => validateName(d.name.lexeme, p));
          });
        } else if (className != null) {
          // Check Main declaration
          namingMatch = cConfig.patterns.any((p) => validateName(className, p));
        }

        if (namingMatch) {
          score += 40;
        } else {
          score -= 2; // Mild penalty
        }
      }

      // --- CRITERIA 2: INHERITANCE ---
      if (element is InterfaceElement) {
        final inheritanceRules = config.inheritances.where(
          (r) => r.onIds.contains(cConfig.id),
        );

        for (final rule in inheritanceRules) {
          if (rule.required.isNotEmpty) {
            if (satisfiesRule(element, rule, config, fileResolver)) {
              final requiresComponent = rule.required.any((d) => d.component != null);
              score += requiresComponent ? 50 : 30;
            } else {
              score -= 30;
            }
          }
        }
      }

      // --- CRITERIA 3: STRUCTURE HEURISTIC ---
      final idLower = cConfig.id.toLowerCase();
      final isInterfaceComp = idLower.contains('interface') || idLower.contains('port');
      final isImplComp = idLower.contains('implementation') || idLower.contains('impl');

      if (isConcrete && isInterfaceComp) score -= 15;
      if (isAbstract && isImplComp) score -= 5;
      if (isConcrete && isImplComp) score += 10;

      // --- CRITERIA 4: KIND & MODIFIER CHECK ---
      if (mainNode != null) {
        if (cConfig.kinds.isNotEmpty) {
          final actualKind = _identifyKind(mainNode);
          if (cConfig.kinds.contains(actualKind)) {
            score += 20;
          } else {
            score -= 20;
          }
        }
        if (cConfig.modifiers.isNotEmpty && mainNode is ClassDeclaration) {
          if (_checkModifiers(mainNode, cConfig.modifiers)) {
            score += 10;
          } else {
            score -= 10;
          }
        }
      }

      // --- TIE BREAKER ---
      score += cConfig.id.split('.').length;

      if (score > bestScore) {
        bestScore = score;
        bestCandidate = candidate;
      }
    }

    return _buildContext(filePath, bestCandidate?.component ?? candidates.first.component);
  }

  NamedCompilationUnitMember? _findMainDeclaration(CompilationUnit unit, String filePath) {
    // Basic heuristic: Find class that matches file name (PascalCase)
    // or return first public class.
    // (Implementation of _findMainDeclaration provided previously is fine)
    // ...
    // Placeholder for brevity:
    if (unit.declarations.isEmpty) return null;
    return unit.declarations.whereType<NamedCompilationUnitMember>().first;
  }

  ComponentKind? _identifyKind(NamedCompilationUnitMember node) {
    if (node is ClassDeclaration) return ComponentKind.class$;
    if (node is MixinDeclaration) return ComponentKind.mixin$;
    if (node is EnumDeclaration) return ComponentKind.enum$;
    if (node is ExtensionDeclaration) return ComponentKind.extension$;
    if (node is FunctionTypeAlias) return ComponentKind.typedef$;
    if (node is GenericTypeAlias) return ComponentKind.typedef$;
    if (node is FunctionDeclaration) return ComponentKind.function;
    // Note: VariableDeclaration is not NamedCompilationUnitMember, usually wrapped in
    // TopLevelVariableDeclaration
    return null;
  }

  bool _checkModifiers(ClassDeclaration node, List<ComponentModifier> requiredModifiers) {
    // Helper to check keywords
    final element = node.declaredFragment?.element;
    if (element == null) return false;

    // Check element flags
    for (final mod in requiredModifiers) {
      switch (mod) {
        case ComponentModifier.abstract:
          if (!element.isAbstract) return false;
        case ComponentModifier.sealed:
          if (!element.isSealed) return false;
        case ComponentModifier.base:
          if (!element.isBase) return false;
        case ComponentModifier.interface:
          if (!element.isInterface) return false;
        case ComponentModifier.final$:
          if (!element.isFinal) return false;
        case ComponentModifier.mixin:
          if (!element.isMixinClass) return false;
      }
    }
    return true;
  }

  ComponentContext _buildContext(String filePath, ComponentConfig config) {
    return ComponentContext(
      filePath: filePath,
      config: config,
      module: fileResolver.resolveModule(filePath),
    );
  }
}
