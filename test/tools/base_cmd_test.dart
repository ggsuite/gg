// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_check/src/tools/base_cmd.dart';
import 'package:test/test.dart';

void main() {
  group('BaseCmd', () {
    final logs = <String>[];

    // .........................................................................
    setUp(
      () {
        BaseCmd.testIsGitHub = false;
        logs.clear();
      },
    );

    // #########################################################################
    group('example', () {
      test('should work fine', () async {
        final baseCmd = BaseCmd.example(
          log: (String log) => logs.add(log),
        );

        // The result should be written to stdout
        await baseCmd.run();

        // Expect right std out
        const cr = BaseCmd.carriageReturn;
        expect(logs, [
          '⌛️ Example command',
          '$cr✅ Example command',
        ]);
      });
    });

    // #########################################################################
    group('with isGitHub == true', () {
      test('should print no carriage returns and no clock icon', () async {
        /// Emulate githuab
        BaseCmd.testIsGitHub = true;

        // Execute command
        final shellCmd = BaseCmd.example(
          log: (String log) => logs.add(log),
        );

        // The result should be written to stdout
        final (exitCode, stdouts, stderrs) = await shellCmd.run();
        expect(exitCode, 0);
        expect(stdouts, ['outputs']);
        expect(stderrs, ['errors']);

        // On GitHub we are not allowed to use carriage returns
        // Also no clock icon is written
        expect(logs, [
          '⌛️ Example command',
          '✅ Example command',
        ]);

        // No errors should have been happened
      });
    });

    // #########################################################################
    test('should log errors', () async {
      final shellCmd = BaseCmd.example(
        log: (String log) => logs.add(log),
        task: () async => (1, <String>[], ['error message']),
      );

      // The result should be written to stdout and stderr
      final (_, messages, errors) = await shellCmd.run();
      expect(messages, isEmpty);
      expect(
        errors[0],
        contains(
          'error message',
        ),
      );

      // On GitHub we are not allowed to use carriage returns
      // Also no clock icon is written
      const cr = BaseCmd.carriageReturn;
      expect(logs, [
        '⌛️ Example command',
        '$cr❌ Example command',
        'error message',
      ]);

      // No errors should have been happened
    });

    // #########################################################################
    test('complete coverage', () async {
      final shellCmd = BaseCmd.example(
        log: null,
      );

      await shellCmd.run();
    });
  });
}
