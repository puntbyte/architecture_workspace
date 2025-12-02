// lib/src/models/details/inheritance_detail.dart

part of '../configs/inheritances_config.dart';

class InheritanceDetail {
  final String? name;
  final String? import;
  final String? component;

  const InheritanceDetail({this.name, this.import, this.component});

  static List<InheritanceDetail> fromMapWithExpansion(
    Map<String, dynamic> map,
    TypesConfig typeDefinitions,
  ) {
    // 1. Check if 'type' key exists (e.g., type: 'usecase.unary')
    // It can be a String or a List<String>.
    final typeValue = map[ConfigKey.rule.type];

    if (typeValue != null) return _expandFromType(typeValue, typeDefinitions);

    // 2. Standard Name/Import Logic
    final import = map.asStringOrNull(ConfigKey.rule.import);
    final component = map.asStringOrNull(ConfigKey.rule.component);

    final nameValue = map[ConfigKey.rule.name];
    if (nameValue is List) {
      return nameValue
          .map(
            (n) => InheritanceDetail(
              name: n.toString(),
              import: import,
              component: component,
            ),
          )
          .toList();
    }

    final singleDetail = InheritanceDetail(
      name: map.asStringOrNull(ConfigKey.rule.name),
      import: import,
      component: component,
    );

    if (singleDetail.name == null && singleDetail.component == null) return [];

    return [singleDetail];
  }

  static List<InheritanceDetail> _expandFromType(dynamic typeValue, TypesConfig typeDefs) {
    final keys = typeValue is List ? typeValue : [typeValue];
    final results = <InheritanceDetail>[];

    for (final key in keys) {
      if (key is! String) continue;

      final typeRule = typeDefs.get(key);
      if (typeRule != null) {
        results.add(
          InheritanceDetail(
            name: typeRule.name,
            import: typeRule.import,
            // Type definitions don't usually store 'component', so it's null
          ),
        );
      }
    }
    return results;
  }
}
