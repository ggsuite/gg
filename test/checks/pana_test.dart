// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:colorize/colorize.dart';
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
      final successReport =
          File('test/data/pana_success_report.json').readAsStringSync();

      fakeProcess = FakeProcess(
        processResult: ProcessResult(0, 0, successReport, ''),
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
      final notSuccessReport =
          File('test/data/pana_not_success_report.json').readAsStringSync();

      fakeProcess = FakeProcess(
        processResult: ProcessResult(0, 0, notSuccessReport, ''),
      );

      pana = Pana.example(
        log: (msg) => messages.add(msg),
        runProcess: fakeProcess.run,
      );

      // Did print red message?
      await pana.run();
      expect(
        hasLog(
          Colorize('[x] 0/10 points: Provide a valid `pubspec.yaml`')
              .red()
              .toString(),
          messages,
        ),
        isTrue,
      );

      // Did print gray details?
      expect(
        hasLog(
          Colorize(
            '* `pubspec.yaml` doesn\'t have a `homepage` entry.',
          ).darkGray().toString(),
          messages,
        ),
        isTrue,
      );

      // Did print gray details?
      expect(
        hasLog(
          Colorize(
            '* `pubspec.yaml` doesn\'t have a `repository` entry.',
          ).darkGray().toString(),
          messages,
        ),
        isTrue,
      );
    });
  });
}
