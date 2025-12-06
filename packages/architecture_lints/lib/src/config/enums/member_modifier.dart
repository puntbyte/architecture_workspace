import 'package:collection/collection.dart';

enum MemberModifier {
  final$('final'),
  const$('const'),
  static$('static'),
  late$('late')
  ;

  final String yamlKey;

  const MemberModifier(this.yamlKey);

  static MemberModifier? fromKey(String? key) {
    return MemberModifier.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}
