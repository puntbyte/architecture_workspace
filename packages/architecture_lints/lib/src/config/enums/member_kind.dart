import 'package:collection/collection.dart';

enum MemberKind {
  method('method'),
  field('field'),
  getter('getter'),
  setter('setter'),
  constructor('constructor'),
  override('override')
  ;

  final String yamlKey;

  const MemberKind(this.yamlKey);

  static MemberKind? fromKey(String? key) =>
      MemberKind.values.firstWhereOrNull((kind) => kind.yamlKey == key);
}
