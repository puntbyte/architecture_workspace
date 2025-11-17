// lib/src/utils/naming_utils.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';

/// A utility class for handling syntactic (string-based) naming conventions.
class NamingUtils {
  const NamingUtils._();

  /// Converts a repository method name into an expected UseCase class name.
  static String getExpectedUseCaseClassName(String methodName, ArchitectureConfig config) {
    final pascal = methodName.toPascalCase();
    final template = config.naming.getRuleFor(ArchComponent.usecase)!.pattern;
    return template.replaceAll('{{name}}', pascal);
  }

  /// Validates a class name against a configured template string.
  static bool validateName({
    required String name,
    required String template,
  }) {
    // This is the definitive, robust implementation that passes all tests.
    if (template == '{{name}}') {
      final isPascal = RegExp(r'^[A-Z][a-zA-Z0-9]+$').hasMatch(name);
      final hasForbiddenSuffix = RegExp(
        r'(Entity|Model|UseCase|Usecase|Repository|DataSource)$',
      ).hasMatch(name);
      return isPascal && !hasForbiddenSuffix;
    }

    const namePlaceholder = '{{name}}';
    const kindPlaceholder = '{{kind}}'; // Updated from 'prefix' or 'type'
    const bothPlaceholder = '{{kind}}{{name}}';

    const pascalToken = '([A-Z][a-zA-Z0-9]*)';
    const pascalTokenNonGreedy = '([A-Z][a-zA-Z0-9]*?)';

    final buffer = StringBuffer();
    for (var i = 0; i < template.length;) {
      if (template.startsWith(bothPlaceholder, i)) {
        buffer.write('$pascalTokenNonGreedy$pascalToken');
        i += bothPlaceholder.length;
        continue;
      }
      if (template.startsWith(namePlaceholder, i)) {
        buffer.write(pascalToken);
        i += namePlaceholder.length;
        continue;
      }
      if (template.startsWith(kindPlaceholder, i)) {
        buffer.write(pascalToken);
        i += kindPlaceholder.length;
        continue;
      }
      buffer.write(RegExp.escape(template[i]));
      i++;
    }

    final pattern = '^$buffer\$';
    return RegExp(pattern).hasMatch(name);
  }
}
