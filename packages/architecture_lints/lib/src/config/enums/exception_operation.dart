import 'package:collection/collection.dart';

enum ExceptionOperation {
  tryReturn('try_return', 'Return value inside a try block'),
  catchReturn('catch_return', 'Return value inside a catch block'),
  catchThrow('catch_throw', 'Throw exception inside a catch block'),
  throw$('throw', 'Explicit throw statement'),
  rethrow$('rethrow', 'Rethrow statement')
  ;

  final String yamlKey;
  final String description;

  const ExceptionOperation(this.yamlKey, this.description);

  static ExceptionOperation? fromKey(String? key) {
    return ExceptionOperation.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}
