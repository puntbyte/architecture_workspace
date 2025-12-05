import 'package:collection/collection.dart';

enum MemberKind {
  method('method'),
  field('field'),
  getter('getter'),
  setter('setter'),
  constructor('constructor'),
  overrideKind('override')
  ; // Special handling for @override

  final String yamlKey;

  const MemberKind(this.yamlKey);

  static MemberKind? fromKey(String? key) {
    return MemberKind.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}
