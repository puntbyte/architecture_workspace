import 'package:architecture_lints/src/engines/component/refinement/refinement_context.dart';
import 'package:architecture_lints/src/engines/component/refinement/score_log.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';

abstract class RefinementStrategy {
  /// Evaluates the candidate and updates the [log].
  void evaluate({
    required ScoreLog log,
    required RefinementContext context,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
  });
}
