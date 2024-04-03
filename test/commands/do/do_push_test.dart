// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/gg.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() async {
  final (dLocal, dRemote) = await initLocalAndRemoteGit();
  final messages = <String>[];
  final ggLog = messages.add;
  await addAndCommitPubspecFile(dLocal);
  await addAndCommitSampleFile(dLocal);
  await pushLocalChanges(dLocal);
  late DoPush doPush;
  late CanPush canPush;
  registerFallbackValue(dLocal);

  // ...........................................................................
  void mockCanPush(bool success) {
    if (success) {
      when(() => canPush.exec(directory: any(named: 'directory'), ggLog: ggLog))
          .thenAnswer((_) async => {});
      return;
    } else {
      when(() => canPush.exec(directory: any(named: 'directory'), ggLog: ggLog))
          .thenThrow(Exception('Cannot push.'));
      return;
    }
  }

  // ...........................................................................
  setUp(() async {
    canPush = MockCanPush();
    mockCanPush(true);
    doPush = DoPush(ggLog: ggLog, canPush: canPush);
    await hardReset(dLocal);
  });

  // ...........................................................................
  tearDownAll(() async {
    await dLocal.delete(recursive: true);
    await dRemote.delete(recursive: true);
  });

  group('DoPush', () {
    group('exec', () {
      group('should log', () {
        group('»Checks successful. Pushed successful.«', () {
          group('and »Already checked and pushed.«', () {
            test(
              'when executed the first and the second time',
              () async {
                // Make a change that could be pushed
                await updateAndCommitSampleFile(dLocal);

                // Let check's pass
                mockCanPush(true);

                // Push the change the first time
                await doPush.exec(directory: dLocal, ggLog: ggLog);
                expect(
                  messages.last,
                  yellow('Checks successful. Pushed successful.'),
                );

                // Execute the same push a second time
                await doPush.exec(directory: dLocal, ggLog: ggLog);
                expect(
                  messages.last,
                  yellow('Already checked and pushed.'),
                );
              },
            );
          });
        });

        group('»Checks successful. Nothing to push.«', () {
          test('when already pushed, but not checked', () async {
            // Make a change that could be pushed
            await updateAndCommitSampleFile(dLocal);

            // Push the change with git directly
            await pushLocalChanges(dLocal);

            // Execute the command
            await doPush.exec(directory: dLocal, ggLog: ggLog);

            // Check the log
            expect(
              messages.last,
              yellow('Checks successful. Nothing to push.'),
            );
          });
        });
      });

      group('should read --force from args', () {
        test('when not specified', () async {
          // Make git push succeed
          final processWrapper = MockGgProcessWrapper();

          when(
            () => processWrapper.run(
              'git',
              ['push', '-f'],
              workingDirectory: dLocal.path,
            ),
          ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

          // Make a change that could be pushed
          await updateAndCommitSampleFile(dLocal);

          // Let check's pass
          mockCanPush(true);

          // Create the command
          final doPush = DoPush(
            ggLog: ggLog,
            canPush: canPush,
            processWrapper: processWrapper,
          );

          // Create a command runner
          final runner = CommandRunner<void>('test', 'test');
          runner.addCommand(doPush);

          // Execute the command
          await runner.run(['push', '--input', dLocal.path, '--force']);

          // Make sure the force flag is passed to git
          verify(
            () => processWrapper.run(
              'git',
              ['push', '-f'],
              workingDirectory: dLocal.path,
            ),
          ).called(1);
        });
      });
      group('should throw', () {
        test('when canPush throws', () async {
          // Make a change that could be pushed
          await updateAndCommitSampleFile(dLocal);

          // Let canPush fail
          mockCanPush(false);

          // Execute doPoush -> should fail
          late String exception;
          try {
            await doPush.exec(directory: dLocal, ggLog: ggLog);
          } catch (e) {
            exception = e.toString();
          }

          expect(exception, 'Exception: Cannot push.');
        });

        test('when »git push« throws', () async {
          // Make git fail
          final processWrapper = MockGgProcessWrapper();

          when(
            () => processWrapper.run(
              'git',
              ['push'],
              workingDirectory: dLocal.path,
            ),
          ).thenAnswer((_) async => ProcessResult(1, 1, '', 'Some error'));

          // Let check's pass
          mockCanPush(true);

          // Make a change that could be pushed
          await updateAndCommitSampleFile(dLocal);

          // Create the command
          final doPush = DoPush(
            ggLog: ggLog,
            canPush: canPush,
            processWrapper: processWrapper,
          );

          // Execute the command
          late String exception;
          try {
            await doPush.exec(directory: dLocal, ggLog: ggLog);
          } catch (e) {
            exception = e.toString();
          }

          expect(exception, 'Exception: git push failed: Some error');
        });
      });

      test('should have a code coverage of 100%', () {
        DoPush(ggLog: ggLog);
      });
    });
  });
}
