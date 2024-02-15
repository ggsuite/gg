// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_check/src/tools/base_cmd.dart';
import 'package:gg_check/src/tools/shell_cmd.dart';
import 'package:test/test.dart';

void main() {
  final logs = <String>[];
  BaseCmd.testIsGitHub = false;

  // ...........................................................................
  setUp(() {
    logs.clear();
  });

  group('RunShellCmd', () {
    // #########################################################################
    group('example', () {
      // .....................................................................
      test('should execute "echo hallo"', () async {
        final shellCmd = ShellCmd.example(
          log: (String log) => logs.add(log),
        );

        // The result should be written to stdout
        final (_, stdouts, stderrs) = await shellCmd.run();

        // Expect right std out
        expect(stdouts, ['hallo\n']);

        // Start and stop messages should have been written to logs
        const cr = BaseCmd.carriageReturn;
        expect(logs, [
          '⌛️ Example command',
          '$cr✅ Example command',
        ]);

        // No errors should have been happened
        expect(stderrs, <String>[]);
      });
    });

    // #########################################################################
    test('should log errors', () async {
      final shellCmd = ShellCmd.example(
        log: (String log) => logs.add(log),
        command: 'ls non_existent_file_or_directory',
        isGitHub: true,
      );

      // The result should be written to stdout and stderr
      final (_, stdouts, stderrs) = await shellCmd.run();
      expect(stdouts, <String>[]);
      expect(
        stderrs[0],
        contains(
          'No such file or directory',
        ),
      );

      // Also no clock icon is written
      const cr = BaseCmd.carriageReturn;
      expect(
        logs[0],
        '⌛️ Example command',
      );
      expect(
        logs[1],
        '$cr❌ Example command',
      );

      expect(logs[2], contains('No such file or directory\n'));

      // No errors should have been happened
    });

    // #########################################################################
    test('complete coverage', () async {
      final shellCmd = ShellCmd.example(
        log: null,
      );

      await shellCmd.run();
    });
  });
}
