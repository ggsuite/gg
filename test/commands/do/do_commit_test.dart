// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/src/commands/can/can_commit.dart';
import 'package:gg/src/commands/do/do_commit.dart';
import 'package:gg_changelog/gg_changelog.dart';
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

    // Insert CHANGELOG.md
    await addAndCommitSampleFile(
      d,
      fileName: 'CHANGELOG.md',
      content: '# Changelog',
    );

    // Insert pubspec.yaml
    await addAndCommitSampleFile(
      d,
      fileName: 'pubspec.yaml',
      content:
          'version: 1.0.0\n' 'repository:https://github.com/inlavigo/gg.git',
    );

    // Mock stuff
    canCommit = MockCanCommit();
    mockCanCommit();

    // Create command
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
      group('should log »Already checked and committed.«', () {
        test('when the command is executed the second time', () async {
          // Execute command the first time
          await doCommit.exec(
            directory: d,
            ggLog: ggLog,
            message: 'My commit',
            logType: LogType.added,
          );

          // Execute command the second time
          await doCommit.exec(
            directory: d,
            ggLog: ggLog,
            message: 'My commit 2',
            logType: LogType.added,
          );

          expect(messages.last, yellow('Already checked and committed.'));
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
            logType: LogType.added,
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
            logType: LogType.added,
          );

          expect(
            messages.last,
            yellow('Checks successful. Commit successful.'),
          );
        });
      });

      test('should write the message and the log type to CHANGELOG.md',
          () async {
        // Add uncommitted file
        await addFileWithoutCommitting(d);

        // Execute command the first time
        await doCommit.exec(
          directory: d,
          ggLog: ggLog,
          message: 'My very special commit message',
          logType: LogType.added,
        );

        // Check CHANGELOG.md
        final changelog = await File('${d.path}/CHANGELOG.md').readAsString();
        expect(changelog, contains('# Changelog\n'));
        expect(changelog, contains('## Unreleased\n'));
        expect(changelog, contains('## Added\n'));
        expect(changelog, contains('My very special commit message\n'));
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
              logType: LogType.added,
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
              ['commit', '-m', 'Add: My commit'],
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
              logType: LogType.added,
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
              logType: LogType.added,
            );
          } catch (e) {
            exception = e.toString();
          }

          expect(
            exception,
            'Exception: ${yellow('Run again with ')}'
            '${blue('-m "yourMessage"')}',
          );
        });

        test('when no log-type is provided', () async {
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
              message: 'My message',
              logType: null, // no log-type
            );
          } catch (e) {
            exception = e.toString();
          }

          final part0 = yellow('Run again with ');

          final part1 = blue(
            '-l added | changed | deprecated | fixed | removed | security',
          );

          expect(
            exception,
            'Exception: $part0$part1',
          );
        });

        test('when pubspec.yaml does not contain a repo URL', () async {
          // Remove repository URL from pubspec.yaml
          await File('${d.path}/pubspec.yaml').writeAsString(
            'version: 1.0.0\n',
          );

          await addFileWithoutCommitting(d);

          late String exception;

          try {
            await doCommit.exec(
              directory: d,
              ggLog: ggLog,
              message: 'My message',
              logType: LogType.fixed,
            );
          } catch (e) {
            exception = e.toString();
          }

          expect(
            exception,
            'Exception: No »repository:« found in pubspec.yaml',
          );
        });
      });

      group('should allow to execute from cli', () {
        test('with message', () async {
          await addFileWithoutCommitting(d);

          final runner = CommandRunner<void>('test', 'test');
          runner.addCommand(doCommit);
          await runner
              .run(['commit', '-i', d.path, '-m', 'My commit', '-l', 'added']);
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
