// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_capture_print/gg_capture_print.dart';
import 'package:gg/gg.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  late CommandRunner<void> runner;
  late Directory tmpDir;

  setUp(() {
    messages.clear();
    runner = CommandRunner<void>('test', 'test');
    final analyze = Analyze(ggLog: messages.add);
    runner.addCommand(analyze);
    tmpDir = Directory.systemTemp.createTempSync();
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Analyze', () {
    group('run()', () {
      // .......................................................................
      group('should print a usage description', () {
        test('when called with args=[--help]', () async {
          await capturePrint(
            ggLog: messages.add,
            code: () => runner.run(['analyze', '--help']),
          );

          expect(messages.last, contains('Runs »dart analyze«.'));
        });
      });

      // .......................................................................
      group('should throw', () {
        test('if input is missing', () async {
          await expectLater(
            runner.run(['analyze', '--input=some-unknown-dir']),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains('Directory "some-unknown-dir" does not exist.'),
              ),
            ),
          );
        });

        test('if dart analyze does exit with error', () async {
          // Create a mock process wrapper
          final processWrapper = MockGgProcessWrapper();

          // Configure runner and command
          final runner = CommandRunner<void>('test', 'test');
          runner.addCommand(
            Analyze(ggLog: messages.add, processWrapper: processWrapper),
          );

          // Make process wrapper returning an error
          when(
            () => processWrapper.run(
              any(),
              any(),
              workingDirectory: any(named: 'workingDirectory'),
            ),
          ).thenAnswer(
            (_) => Future.value(ProcessResult(1, 1, 'stdout', 'stderr')),
          );

          // Run the command
          await expectLater(
            () => runner.run(['analyze', tmpDir.path]),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('"dart analyze" failed. See log for details.'),
              ),
            ),
          );

          // An error should have been logged
          expect(messages[0], contains('⌛️ Running "dart analyze"'));
          expect(messages[1], contains('❌ Running "dart analyze"'));
        });
      });

      // .......................................................................
      group('should succeed', () {
        group('when called with right input param', () {
          test('and no analyze errors in code', () async {
            await runner.run(['analyze', '--input', tmpDir.path]);
            expect(messages[0], contains('⌛️ Running "dart analyze"'));
            expect(messages[1], contains('✅ Running "dart analyze"'));
          });
        });
      });
    });
  });
}
