import 'package:architecture_lints/src/lints/boundaries/logic/package_logic.dart';
import 'package:test/test.dart';

class PackageLogicTester with PackageLogic {}

void main() {
  group('PackageLogic', () {
    final tester = PackageLogicTester();
    const projectName = 'my_app';

    test('isExternalUri identifies external packages', () {
      expect(tester.isExternalUri('dart:async', projectName), isTrue);
      expect(tester.isExternalUri('package:flutter/material.dart', projectName), isTrue);

      // Internal
      expect(tester.isExternalUri('package:my_app/main.dart', projectName), isFalse);
      expect(tester.isExternalUri('../relative.dart', projectName), isFalse);
    });

    test('matchesAnyPattern matches globs', () {
      final patterns = ['package:flutter/**', 'dart:*'];

      expect(tester.matchesAnyPattern('package:flutter/material.dart', patterns), isTrue);
      expect(tester.matchesAnyPattern('dart:io', patterns), isTrue);
      expect(tester.matchesAnyPattern('package:bloc/bloc.dart', patterns), isFalse);
    });
  });
}