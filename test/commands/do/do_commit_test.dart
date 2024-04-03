// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/src/commands/can/can_commit.dart';
import 'package:gg/src/commands/do/do_commit.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late DoCommit doCommit;
  final messages = <String>[];
  final ggLog = messages.add;

  late CanCommit canCommit;

  // ...........................................................................
  void mockCanCommit() {
    registerFallbackValue(d);

    when(
      () => canCommit.exec(
        directory: any(named: 'directory'),
        ggLog: ggLog,
        force: null,
      ),
    ).thenAnswer((_) => Future.value());
  }

  // ...........................................................................
  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    await initGit(d);
    await addAndCommitSampleFile(d);
    canCommit = MockCanCommit();
    mockCanCommit();

    doCommit = DoCommit(
      ggLog: ggLog,
      canCommit: canCommit,
    );
  });

  // ...........................................................................
  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('DoCommit', () {
    group('exec(directory, ggLog, message)', () {
      group('should log »Already committed and checked.«', () {
        test('when the command is executed the second time', () async {
          // Execute command the first time
          await doCommit.exec(
            directory: d,
            ggLog: ggLog,
            message: 'My commit',
          );

          // Execute command the second time
          await doCommit.exec(
            directory: d,
            ggLog: ggLog,
            message: 'My commit 2',
          );

          expect(messages.last, yellow('Already committed and checked.'));
        });
      });

      group('should log »Checks successful. Nothing to commit.«', () {
        test(
            'when the command is executed the first time '
            'but nothing needs to be committed.', () async {
          // Execute command the first time
          await doCommit.exec(
            directory: d,
            ggLog: ggLog,
            message: 'My commit',
          );

          expect(
            messages.last,
            yellow('Checks successful. Nothing to commit.'),
          );
        });
      });

      group('should commit and log »Checks successful. Commit successful.«',
          () {
        test(
            'when the command is executed the first time '
            'and uncommitted changes were committed.', () async {
          // Add uncommitted file
          await addFileWithoutCommitting(d);

          // Execute command the first time
          await doCommit.exec(
            directory: d,
            ggLog: ggLog,
            message: 'My commit',
          );

          expect(
            messages.last,
            yellow('Checks successful. Commit successful.'),
          );
        });
      });

      group('should throw', () {
        test('when »git add finishes with an error', () async {
          // Mock the error
          final processWrapper = MockGgProcessWrapper();

          when(
            () => processWrapper.run(
              'git',
              ['add', '.'],
              workingDirectory: d.path,
            ),
          ).thenAnswer(
            (_) => Future.value(
              ProcessResult(
                1,
                1,
                '',
                'Some error',
              ),
            ),
          );

          mockCanCommit();

          // Add an uncommitted file
          await addFileWithoutCommitting(d);

          // Execute the command
          final doCommit = DoCommit(
            ggLog: ggLog,
            canCommit: canCommit,
            processWrapper: processWrapper,
          );

          late String exception;

          try {
            await doCommit.exec(
              directory: d,
              ggLog: ggLog,
              message: 'My commit',
            );
          } catch (e) {
            exception = e.toString();
          }

          expect(exception, 'Exception: git add failed: Some error');
        });

        test('when »git commit finishes with an error', () async {
          // Make git commit failing
          final processWrapper = MockGgProcessWrapper();
          when(
            () => processWrapper.run(
              'git',
              ['commit', '-m', 'My commit'],
              workingDirectory: d.path,
            ),
          ).thenAnswer(
            (_) => Future.value(
              ProcessResult(
                1,
                1,
                '',
                'Some error',
              ),
            ),
          );

          // Make git add working
          when(
            () => processWrapper.run(
              'git',
              ['add', '.'],
              workingDirectory: d.path,
            ),
          ).thenAnswer(
            (_) => Future.value(
              ProcessResult(
                1,
                0,
                '',
                '',
              ),
            ),
          );

          mockCanCommit();

          // Add an uncommitted file
          await addFileWithoutCommitting(d);

          // Execute the command
          final doCommit = DoCommit(
            ggLog: ggLog,
            canCommit: canCommit,
            processWrapper: processWrapper,
          );

          late String exception;

          try {
            await doCommit.exec(
              directory: d,
              ggLog: ggLog,
              message: 'My commit',
            );
          } catch (e) {
            exception = e.toString();
          }

          expect(exception, 'Exception: git commit failed: Some error');
        });

        test('when no message is provided', () async {
          // Add an uncommitted file
          await addFileWithoutCommitting(d);

          // Execute the command
          final doCommit = DoCommit(
            ggLog: ggLog,
            canCommit: canCommit,
          );

          late String exception;

          try {
            await doCommit.exec(
              directory: d,
              ggLog: ggLog,
              message: null, // no message
            );
          } catch (e) {
            exception = e.toString();
          }

          expect(
            exception,
            contains(red('Message missing.\n')),
          );

          expect(
            exception,
            contains(darkGray('Run command again with ')),
          );

          expect(
            exception,
            contains(yellow('--message ')),
          );

          expect(
            exception,
            contains(blue('"your message"')),
          );
        });
      });

      group('should allow to execute from cli', () {
        test('with message', () async {
          await addFileWithoutCommitting(d);

          final runner = CommandRunner<void>('test', 'test');
          runner.addCommand(doCommit);
          await runner.run(['commit', '-i', d.path, '-m', 'My commit']);
          expect(
            messages.last,
            yellow('Checks successful. Commit successful.'),
          );
        });
      });
      test('should have 100% code coverage', () {
        final instance = DoCommit(ggLog: ggLog);
        expect(instance, isNotNull);
      });
    });
  });
}
