import 'package:collection/collection.dart';

enum MemberModifier {
  finalMod('final'),
  constMod('const'),
  staticMod('static'),
  lateMod('late')
  ;

  final String yamlKey;

  const MemberModifier(this.yamlKey);

  static MemberModifier? fromKey(String? key) {
    return MemberModifier.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}
