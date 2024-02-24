// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_check/src/checks/pana.dart';
import 'package:test/test.dart';

import '../helpers/fake_process.dart';
import '../helpers/has_log.dart';
import '../helpers/run_command.dart';

void main() {
  final messages = <String>[];

  late FakeProcess fakeProcess;
  late Pana pana;

  // ...........................................................................
  void init() {
    fakeProcess = FakeProcess();
    pana = Pana.example(
      log: (msg) => messages.add(msg),
      runProcess: fakeProcess.run,
    );
  }

  group('Pana', () {
    // #########################################################################

    // .........................................................................
    test('should throw an error when pana returns invalid JSON', () async {
      init();
      await runCommand(cmd: pana, args: ['pana']);
      expect(hasLog('❌ gg check pana', messages), isTrue);
      expect(
        hasLog(
          'Error parsing pana output: FormatException: '
          'Unexpected end of input',
          messages,
        ),
        isTrue,
      );
    });

    // .........................................................................
    test('should succeed when 140 pubpoints are reached', () async {
      fakeProcess = FakeProcess(
        processResult: ProcessResult(
          0,
          0,
          '{"scores": {"grantedPoints": 140,"maxPoints": 140}}',
          '',
        ),
      );

      pana = Pana.example(
        log: (msg) => messages.add(msg),
        runProcess: fakeProcess.run,
      );

      await runCommand(cmd: pana, args: ['pana']);
      expect(hasLog('✅ gg check pana', messages), isTrue);
    });

    // .........................................................................
    test('should fail when 140 pubpoints are not reached', () async {
      fakeProcess = FakeProcess(
        processResult: ProcessResult(
          0,
          0,
          '{"scores": {"grantedPoints": 130,"maxPoints": 140}}',
          '',
        ),
      );

      pana = Pana.example(
        log: (msg) => messages.add(msg),
        runProcess: fakeProcess.run,
      );

      await runCommand(cmd: pana, args: ['pana']);
      expect(hasLog('Not all pub points achieved: 130/140', messages), isTrue);
      expect(hasLog('run "dart run pana" for more details', messages), isTrue);
    });
  });
}
