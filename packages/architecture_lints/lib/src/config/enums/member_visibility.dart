import 'package:collection/collection.dart';

enum MemberVisibility {
  public('public'),
  private('private')
  ;

  final String yamlKey;

  const MemberVisibility(this.yamlKey);

  static MemberVisibility? fromKey(String? key) =>
      MemberVisibility.values.firstWhereOrNull((visibility) => visibility.yamlKey == key);
}
