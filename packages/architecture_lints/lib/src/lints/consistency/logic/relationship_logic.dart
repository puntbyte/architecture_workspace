import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/config/enums/relationship_element.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:path/path.dart' as p;

mixin RelationshipLogic on NamingLogic {

  String? extractCoreName(String className, ComponentContext context) {
    if (context.patterns.isEmpty) return className;
    for (final pattern in context.patterns) {
      final coreName = extractCoreNameFromPattern(className, pattern);
      if (coreName != null) return coreName;
    }
    return null;
  }

  String generateTargetClassName(String coreName, ComponentConfig targetConfig) {
    if (targetConfig.patterns.isEmpty) return coreName;
    final pattern = targetConfig.patterns.first;
    return pattern
        .replaceAll('{{name}}', coreName)
        .replaceAll('{{affix}}', '');
  }

  String toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp('([a-z])([A-Z])'), (Match m) => '${m[1]}_${m[2]}')
        .toLowerCase();
  }

  ParityTarget? findMissingTarget({
    required AstNode node,
    required ArchitectureConfig config,
    required ComponentContext currentComponent,
    required FileResolver fileResolver,
    required String currentFilePath,
    bool debug = false, // Enable via ParityMissingRule
  }) {
    String? name;
    RelationshipElement? type;
    String? methodName;

    if (node is ClassDeclaration) {
      name = node.name.lexeme;
      type = RelationshipElement.classElement;
    } else if (node is MethodDeclaration) {
      methodName = node.name.lexeme;
      name = methodName.isEmpty ? '' : '${methodName[0].toUpperCase()}${methodName.substring(1)}';
      type = RelationshipElement.methodElement;
    }

    if (name == null || type == null) return null;

    if (debug) {
      print('DEBUG RELATIONSHIP:');
      print('  Node: "$name" ($type)');
      print('  Current Component: "${currentComponent.id}"');
      print('  Total Rules Loaded: ${config.relationships.length}');
    }

    // Filter rules
    final rules = config.relationships.where((rule) {
      // DEBUG LOGGING FOR FILTERING
      final matchesElement = rule.element == type;
      final matchesId = currentComponent.matchesAny(rule.onIds);

      if (debug) {
        print('  - Rule [on: ${rule.onIds}, kind: ${rule.element?.yamlKey}]:');
        print('    -> Matches Kind? $matchesElement');
        print('    -> Matches ID?   $matchesId');
      }

      if (!matchesElement) return false;

      // Visibility Check
      if (node is MethodDeclaration) {
        final element = node.declaredFragment?.element;
        if (element != null && rule.visibility == 'public' && element.isPrivate) {
          if (debug) print('    -> Failed Visibility (Private)');
          return false;
        }
      }

      return matchesId;
    }).toList();

    if (rules.isEmpty) {
      if (debug) print('  => NO MATCHING RULES FOUND.');
      return null;
    }

    for (final rule in rules) {
      if (debug) print('  => Applying Rule: Target="${rule.targetComponent}"');

      ComponentConfig? targetComponent;
      try {
        targetComponent = config.components.firstWhere((c) => c.id == rule.targetComponent);
      } catch (e) {
        if (debug) print('     Error: Target component "${rule.targetComponent}" not defined in config.');
        continue;
      }

      String? coreName = name;
      if (node is ClassDeclaration) {
        coreName = extractCoreName(name!, currentComponent);
      }

      if (coreName == null) {
        if (debug) print('     Error: Could not extract core name from "$name" using pattern.');
        continue;
      }

      final targetClassName = generateTargetClassName(coreName, targetComponent);
      final targetFileName = '${toSnakeCase(targetClassName)}.dart';

      if (debug) print('     Calculating path for: $targetFileName ($targetClassName)');

      final targetPath = findTargetFilePath(
        currentFilePath: currentFilePath,
        currentComponent: currentComponent.config,
        targetComponent: targetComponent,
        targetFileName: targetFileName,
      );

      if (targetPath != null) {
        return ParityTarget(
          path: targetPath,
          coreName: coreName,
          targetClassName: targetClassName,
          templateId: rule.action,
          sourceComponent: currentComponent.config,
        );
      } else if (debug) {
        print('     Error: Path calculation failed. Check if "${targetComponent.paths}" aligns with current file structure.');
      }
    }
    return null;
  }

  String? findTargetFilePath({
    required String currentFilePath,
    required ComponentConfig currentComponent,
    required ComponentConfig targetComponent,
    required String targetFileName,
  }) {
    final currentDir = p.dirname(currentFilePath);

    for (final path in currentComponent.paths) {
      final configPath = path.replaceAll('/', p.separator);

      // Check for path suffix match
      if (currentDir.endsWith(configPath) || currentDir.endsWith(p.separator + configPath)) {

        final moduleRoot = currentDir.substring(0, currentDir.lastIndexOf(configPath));

        if (targetComponent.paths.isNotEmpty) {
          final targetRelative = targetComponent.paths.first.replaceAll('/', p.separator);
          final targetDir = p.join(moduleRoot, targetRelative);
          return p.normalize(p.join(targetDir, targetFileName));
        }
      }
    }
    return null;
  }
}

class ParityTarget {
  final String path;
  final String coreName;
  final String targetClassName;
  final String? templateId;
  final ComponentConfig sourceComponent;

  ParityTarget({
    required this.path,
    required this.coreName,
    required this.targetClassName,
    required this.templateId,
    required this.sourceComponent,
  });
}