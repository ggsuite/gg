// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/gg.dart';
import 'package:gg_changelog/gg_changelog.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() async {
  late Directory dLocal;
  late Directory dRemote;
  final messages = <String>[];
  final ggLog = messages.add;

  late File ggJson;
  late DoPush doPush;
  late CanPush canPush;
  late CanCommit canCommit;
  late DoCommit doCommit;
  late IsPushed isPushed;

  // ...........................................................................
  void mockCanPush(bool success) {
    if (success) {
      when(
        () => canPush.exec(directory: any(named: 'directory'), ggLog: ggLog),
      ).thenAnswer((_) async => {});
      return;
    } else {
      when(
        () => canPush.exec(directory: any(named: 'directory'), ggLog: ggLog),
      ).thenThrow(Exception('Cannot push.'));
      return;
    }
  }

  // ...........................................................................
  setUp(() async {
    (dLocal, dRemote) = await initLocalAndRemoteGit();

    await addAndCommitPubspecFile(dLocal);
    await addAndCommitSampleFile(dLocal);
    await pushLocalChanges(dLocal);
    registerFallbackValue(dLocal);

    canPush = MockCanPush();
    mockCanPush(true);
    doPush = DoPush(ggLog: ggLog, canPush: canPush);
    canCommit = MockCanCommit();
    doCommit = DoCommit(ggLog: ggLog, canCommit: canCommit);
    isPushed = IsPushed(ggLog: ggLog);
    ggJson = File(join(dLocal.path, '.gg.json'));

    // Init pubspec.yaml
    await File(
      join(dLocal.path, 'pubspec.yaml'),
    ).writeAsString('version: 1.0.0\nrepository: https://foo.com');
    await commitFile(dLocal, 'pubspec.yaml');

    // Init CHANGELOG.md
    await File(join(dLocal.path, 'CHANGELOG.md')).writeAsString('# Changelog');
    await commitFile(dLocal, 'CHANGELOG.md');
  });

  // ...........................................................................
  tearDownAll(() async {
    await dLocal.delete(recursive: true);
    await dRemote.delete(recursive: true);
  });

  group('DoPush', () {
    group('exec', () {
      group('should succeed', () {
        group('and not push', () {
          group('when everything is already pushed', () {
            test('and the hashes are correct', () async {
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
              expect(
                await isPushed.get(directory: dLocal, ggLog: ggLog),
                isTrue,
              );

              // Execute the same push a second time
              await doPush.exec(directory: dLocal, ggLog: ggLog);
              expect(messages.last, yellow('Already checked and pushed.'));
            });
          });
        });

        group('and push', () {
          group('and overwrite the last pushed commit', () {
            test('when force or --force is specified', () async {
              // Make git push succeed
              final processWrapper = MockGgProcessWrapper();

              when(
                () => processWrapper.run('git', [
                  'push',
                  '-f',
                ], workingDirectory: dLocal.path),
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
                () => processWrapper.run('git', [
                  'push',
                  '-f',
                ], workingDirectory: dLocal.path),
              ).called(1);
            });
          });

          group('a new hash', () {
            test('when before was not pushed with »gg do push«', () async {
              // Create a change
              await updateSampleFileWithoutCommitting(dLocal);

              // Commit the change using ggDoCommit
              when(
                () => canCommit.exec(directory: dLocal, ggLog: ggLog),
              ).thenAnswer((_) async => {});
              await doCommit.exec(
                directory: dLocal,
                ggLog: ggLog,
                message: 'Message 0',
                logType: LogType.added,
              );

              // Push the change without ggDoPush
              await pushLocalChanges(dLocal);
              expect(
                await isPushed.get(directory: dLocal, ggLog: ggLog),
                isTrue,
              );

              // Run ggDoPush should update .gg.json
              final ggJsonBefore = await ggJson.readAsString();
              await doPush.exec(directory: dLocal, ggLog: ggLog);
              final ggJsonAfter = await ggJson.readAsString();
              expect(ggJsonBefore, isNot(ggJsonAfter));

              // The new gg.json should be pushed
              expect(
                await isPushed.get(directory: dLocal, ggLog: ggLog),
                isTrue,
              );
            });
          });
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
            () => processWrapper.run('git', [
              'push',
            ], workingDirectory: dLocal.path),
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
    });

    test('should have a code coverage of 100%', () {
      DoPush(ggLog: ggLog);
    });
  });
}
