import 'package:collection/collection.dart';

enum MemberVisibility {
  public('public'),
  private('private')
  ;

  final String yamlKey;

  const MemberVisibility(this.yamlKey);

  static MemberVisibility? fromKey(String? key) {
    return MemberVisibility.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}
