// test/src/analysis/arch_component_test.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:test/test.dart';

void main() {
  group('ArchComponent', () {
    group('fromId factory', () {
      test('should return correct component when id is valid', () {
        expect(ArchComponent.fromId('entity'), ArchComponent.entity);
        expect(ArchComponent.fromId('port'), ArchComponent.port);
        expect(ArchComponent.fromId('repository'), ArchComponent.repository);
        expect(ArchComponent.fromId('event.interface'), ArchComponent.eventInterface);
      });

      test('should return unknown when id is invalid or empty', () {
        expect(ArchComponent.fromId('non_existent_id'), ArchComponent.unknown);
        expect(ArchComponent.fromId(''), ArchComponent.unknown);
      });
    });

    group('children getter (Direct Children)', () {
      test('domain should contain entity, port, and usecase', () {
        // FIX: Use full enum names inside matchers.
        expect(
          ArchComponent.domain.children,
          equals({ArchComponent.entity, ArchComponent.port, ArchComponent.usecase}),
        );
      });

      test('data should contain model, repository, and source', () {
        // FIX: Use full enum names inside matchers.
        expect(
          ArchComponent.data.children,
          equals({ArchComponent.model, ArchComponent.repository, ArchComponent.source}),
        );
      });

      test('presentation should contain page, widget, and manager', () {
        // FIX: Use full enum names inside matchers.
        expect(
          ArchComponent.presentation.children,
          equals({ArchComponent.page, ArchComponent.widget, ArchComponent.manager}),
        );
      });

      test('manager should contain event and state', () {
        // FIX: Use full enum names inside matchers.
        expect(ArchComponent.manager.children, equals({ArchComponent.event, ArchComponent.state}));
      });

      test('leaf components should have empty children', () {
        expect(ArchComponent.entity.children, isEmpty);
        expect(ArchComponent.page.children, isEmpty);
      });
    });

    group('allChildren recursive getter', () {
      test('should return all nested children for a layer component', () {
        final domainChildren = ArchComponent.domain.allChildren;
        // FIX: Use full enum names inside matchers.
        expect(
          domainChildren,
          containsAll({
            ArchComponent.entity,
            ArchComponent.port,
            ArchComponent.usecase,
            ArchComponent.usecaseParameter,
          }),
        );
      });

      test('should return all nested children for a presentation sub-layer', () {
        final managerChildren = ArchComponent.manager.allChildren;
        // FIX: Use full enum names inside matchers.
        expect(
          managerChildren,
          containsAll({
            ArchComponent.event,
            ArchComponent.state,
            ArchComponent.eventInterface,
            ArchComponent.eventImplementation,
            ArchComponent.stateInterface,
            ArchComponent.stateImplementation,
          }),
        );
      });

      test('should return an empty set for a leaf component', () {
        expect(ArchComponent.port.allChildren, isEmpty);
      });
    });

    group('Static Layer Getters (Backward Compatibility)', () {
      test('domainLayer should return correct set', () {
        // FIX: Use full enum names inside matchers.
        expect(
          ArchComponent.domainLayer,
          equals({ArchComponent.entity, ArchComponent.port, ArchComponent.usecase}),
        );
      });

      test('dataLayer should return correct set', () {
        // FIX: Use full enum names inside matchers.
        expect(
          ArchComponent.dataLayer,
          equals({ArchComponent.model, ArchComponent.repository, ArchComponent.source}),
        );
      });

      test('presentationLayer should return correct set', () {
        // FIX: Use full enum names inside matchers.
        expect(
          ArchComponent.presentationLayer,
          equals({
            ArchComponent.page,
            ArchComponent.widget,
            ArchComponent.manager,
            ArchComponent.event,
            ArchComponent.state,
          }),
        );
      });

      test('layer getter should return top level layers', () {
        // FIX: Use full enum names inside matchers.
        expect(
          ArchComponent.layer,
          equals({ArchComponent.domain, ArchComponent.data, ArchComponent.presentation}),
        );
      });
    });
  });
}
