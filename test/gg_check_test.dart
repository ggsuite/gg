// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_check/gg_check.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];

  group('GgCheck()', () {
    // #########################################################################
    group('exec()', () {
      test('description of the test ', () async {
        final ggCheck = GgCheck(param: 'foo', log: (msg) => messages.add(msg));

        await ggCheck.exec();
      });
    });

    // #########################################################################
    group('Command', () {
      test('should allow to run the code from command line', () async {
        final ggCheck = GgCheckCmd(log: (msg) => messages.add(msg));

        final CommandRunner<void> runner = CommandRunner<void>(
          'ggCheck',
          'Description goes here.',
        )..addCommand(ggCheck);

        await runner.run(['ggCheck', '--param', 'foo']);
      });
    });
  });
}
