// test/src/models/inheritances_config_test.dart

import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
// We import the main config file because InheritanceDetail is a part of it.
// This makes InheritanceDetail visible to the test.
import 'package:test/test.dart';

void main() {
  group('InheritanceDetail', () {
    group('tryFromMap', () {
      // --- Existing Name/Import Tests ---
      test('should create instance with valid name and import', () {
        final map = {
          'name': 'BaseEntity',
          'import': 'package:core/entity.dart',
        };
        final detail = InheritanceDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.name, 'BaseEntity');
        expect(detail.import, 'package:core/entity.dart');
        expect(detail.component, isNull);
      });

      // --- NEW: Component Tests ---
      test('should create instance with valid component', () {
        final map = {
          'component': 'entity',
        };
        final detail = InheritanceDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.component, 'entity');
        expect(detail.name, isNull);
        expect(detail.import, isNull);
      });

      test('should allow both name/import AND component (though unlikely usage)', () {
        final map = {
          'name': 'Base',
          'import': 'pkg:a',
          'component': 'entity',
        };
        final detail = InheritanceDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.name, 'Base');
        expect(detail.component, 'entity');
      });

      // --- Validation Tests ---
      test('should return null when both name and component are missing', () {
        // Only import is not enough
        final map = {'import': 'package:core/entity.dart'};
        expect(InheritanceDetail.tryFromMap(map), isNull);
      });

      test('should return null when map is empty', () {
        final map = <String, dynamic>{};
        expect(InheritanceDetail.tryFromMap(map), isNull);
      });

      test('should return null if name is present but not a string', () {
        final map = {'name': 123, 'import': 'pkg:a'};
        expect(InheritanceDetail.tryFromMap(map), isNull);
      });

      test('should return null if component is present but not a string', () {
        final map = {'component': 123};
        expect(InheritanceDetail.tryFromMap(map), isNull);
      });
    });
  });

  group('InheritanceRule', () {
    group('tryFromMap', () {
      test('should create rule with valid on value', () {
        final map = {'on': 'entity'};
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, 'entity');
        expect(rule.required, isEmpty);
        expect(rule.allowed, isEmpty);
        expect(rule.forbidden, isEmpty);
      });

      test('should create rule with required inheritance (Class Name)', () {
        final map = {
          'on': 'entity',
          'required': {'name': 'BaseEntity', 'import': 'package:core/entity.dart'},
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(1));
        expect(rule.required.first.name, 'BaseEntity');
      });

      test('should create rule with required inheritance (Component)', () {
        final map = {
          'on': 'model',
          'required': {'component': 'entity'},
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(1));
        expect(rule.required.first.component, 'entity');
        expect(rule.required.first.name, isNull);
      });

      test('should parse list of maps for mixed details', () {
        final map = {
          'on': 'repository',
          'required': [
            {'name': 'BaseRepo', 'import': 'pkg:repo.dart'}, // Class check
            {'component': 'port'}, // Component check
          ],
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(2));
        expect(rule.required[0].name, 'BaseRepo');
        expect(rule.required[1].component, 'port');
      });

      test('should return null when on is empty', () {
        final map = {'on': ''};
        expect(InheritanceRule.tryFromMap(map), isNull);
      });

      test('should return null when on is missing', () {
        final map = {'required': {'component': 'entity'}};
        expect(InheritanceRule.tryFromMap(map), isNull);
      });
    });
  });

  group('InheritancesConfig', () {
    group('fromMap', () {
      test('should parse complex configuration', () {
        final map = {
          'inheritances': [
            // Domain Layer
            {
              'on': 'entity',
              'required': {'name': 'Entity', 'import': 'package:core/entity.dart'}
            },
            // Data Layer (Model must extend Entity component)
            {
              'on': 'model',
              'required': {'component': 'entity'}
            },
            // Presentation Layer (Mixed allowed)
            {
              'on': 'manager',
              'allowed': [
                {'name': 'Bloc', 'import': 'pkg:bloc'},
                {'name': 'Cubit', 'import': 'pkg:bloc'}
              ]
            }
          ],
        };

        final config = InheritancesConfig.fromMap(map);

        expect(config.rules, hasLength(3));

        final entityRule = config.ruleFor('entity');
        expect(entityRule, isNotNull);
        expect(entityRule!.required.first.name, 'Entity');

        final modelRule = config.ruleFor('model');
        expect(modelRule, isNotNull);
        expect(modelRule!.required.first.component, 'entity');

        final managerRule = config.ruleFor('manager');
        expect(managerRule, isNotNull);
        expect(managerRule!.allowed, hasLength(2));
      });

      test('should handle empty inheritances list', () {
        final config = InheritancesConfig.fromMap({'inheritances': []});
        expect(config.rules, isEmpty);
      });
    });
  });
}