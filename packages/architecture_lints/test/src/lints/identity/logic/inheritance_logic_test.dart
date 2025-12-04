import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:test/test.dart';

class LogicWrapper with InheritanceLogic {}

void main() {
  group('InheritanceLogic', () {
    final logic = LogicWrapper();

    group('componentMatches', () {
      test('should return true for exact match', () {
        expect(logic.componentMatches('domain', 'domain'), isTrue);
        expect(logic.componentMatches('data.repo', 'data.repo'), isTrue);
      });

      test('should return true for prefix (parent) match', () {
        // rule 'domain' should match component 'domain.usecase'
        expect(logic.componentMatches('domain', 'domain.usecase'), isTrue);
        expect(logic.componentMatches('data', 'data.source.local'), isTrue);
      });

      test('should return true for suffix (shorthand) match', () {
        // rule 'model' should match component 'data.model'
        expect(logic.componentMatches('model', 'data.model'), isTrue);
        expect(logic.componentMatches('repository', 'data.repository'), isTrue);
      });

      test('should return false for partial substring match', () {
        // 'user' should NOT match 'domain.usecase' just because 'use' is in there
        expect(logic.componentMatches('user', 'domain.usecase'), isFalse);
        // 'repo' should NOT match 'repository'
        expect(logic.componentMatches('repo', 'data.repository'), isFalse);
      });

      test('should return false for sibling components', () {
        expect(logic.componentMatches('domain', 'data'), isFalse);
      });
    });
  });
}