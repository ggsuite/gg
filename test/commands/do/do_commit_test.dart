// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/src/commands/can/can_commit.dart';
import 'package:gg/src/commands/did/did_commit.dart';
import 'package:gg/src/commands/do/do_commit.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late DoCommit doCommit;
  late DidCommit didCommit;
  late IsCommitted isCommitted;
  late CanCommit canCommit;
  late GgProcessWrapper processWrapper;
  final messages = <String>[];
  final ggLog = messages.add;

  // ...........................................................................
  void mockIsCommitted(bool value) {
    when(
      () => isCommitted.get(
        directory: any(named: 'directory'),
        ggLog: any(named: 'ggLog'),
      ),
    ).thenAnswer((_) async => value);
  }

  // ...........................................................................
  void mockDidCommitGet(bool value) {
    when(
      () => didCommit.get(
        directory: any(named: 'directory'),
        ggLog: any(named: 'ggLog'),
      ),
    ).thenAnswer((_) async => value);
  }

  // ...........................................................................
  void mockDidCommitSet(bool value) {
    when(
      () => didCommit.set(
        directory: any(named: 'directory'),
        success: value,
      ),
    ).thenAnswer((_) async {});
  }

  // ...........................................................................
  void mockCanCommit(bool value) {
    final mock = when(
      () => canCommit.exec(
        directory: any(named: 'directory'),
        ggLog: any(named: 'ggLog'),
      ),
    );
    if (value) {
      mock.thenAnswer((_) async {});
    } else {
      mock.thenThrow(Exception('Cannot commit.'));
    }
  }

  // ...........................................................................
  void mockGitCommit() {
    when(
      () => processWrapper.run(
        'git',
        ['commit', '-m', 'my message'],
        workingDirectory: d.path,
      ),
    ).thenAnswer(
      (_) => Future.value(
        ProcessResult(0, 0, '', ''),
      ),
    );
  }

  // ...........................................................................
  void mockGitAdd() {
    when(
      () => processWrapper.run(
        'git',
        ['add', '.'],
        workingDirectory: d.path,
      ),
    ).thenAnswer(
      (_) => Future.value(
        ProcessResult(0, 0, '', ''),
      ),
    );
  }

  // ...........................................................................
  void verifyDidCommitIsSet(bool value) {
    verify(
      () => didCommit.set(
        directory: any(named: 'directory'),
        success: value,
      ),
    ).called(1);
  }

  // ...........................................................................
  void verifyDidGitAdd() {
    verify(
      () => processWrapper.run(
        'git',
        ['add', '.'],
        workingDirectory: d.path,
      ),
    ).called(1);
  }

  // ...........................................................................
  void verifyDidGitCommit() {
    verify(
      () => processWrapper.run(
        'git',
        ['commit', '-m', 'my message'],
        workingDirectory: d.path,
      ),
    ).called(1);
  }

  // ...........................................................................
  setUpAll(() {
    registerFallbackValue(Directory.systemTemp);
  });

  // ...........................................................................
  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    processWrapper = MockGgProcessWrapper();
    didCommit = MockDidCommit();
    isCommitted = MockIsCommitted();
    canCommit = MockCanCommit();

    doCommit = DoCommit(
      ggLog: ggLog,
      processWrapper: processWrapper,
      didCommit: didCommit,
      isCommitted: isCommitted,
      canCommit: canCommit,
    );

    mockGitCommit();
    mockGitAdd();
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('DoCommit', () {
    group('exec', () {
      group('should check, add and commit the current state,', () {
        test('with mocked dependencies', () async {
          // Assume not everything is commited yet.
          mockIsCommitted(false);

          // Assume didCommit is not yet set
          mockDidCommitGet(false);
          mockDidCommitSet(true);

          // Assume everything is fine
          mockCanCommit(true);

          // Execute the command
          await doCommit.exec(
            directory: d,
            ggLog: ggLog,
            message: 'my message',
          );

          // Expect didCommit is set to true
          verifyDidCommitIsSet(true);
          verifyDidGitAdd();
          verifyDidGitCommit();
        });
      });

      group('should do nothing', () {
        test('if everything is already committed', () async {
          // Assume everything is already committed
          mockIsCommitted(true);

          // Assume didCommit is not already set
          mockDidCommitGet(true);

          // Assume canCommit returns true
          mockCanCommit(true);

          // Execute the command
          await doCommit.exec(
            directory: d,
            ggLog: ggLog,
            message: 'my message',
          );

          // But no git commands are executed
          verifyNever(
            () => processWrapper.run(
              'git',
              ['add', '.'],
              workingDirectory: d.path,
            ),
          );
          verifyNever(
            () => processWrapper.run(
              'git',
              ['commit', '-m', 'my message'],
              workingDirectory: d.path,
            ),
          );
        });
      });

      group('should just update didCommit state', () {
        group('if eveything is already commited but', () {
          test('but the state was not set before', () async {
            // Assume everything is already committed
            mockIsCommitted(true);

            // Assume didCommit is not yet set
            mockDidCommitGet(false);

            // Assume didCommit will be set to true
            mockDidCommitSet(true);

            // Assume canCommit returns true
            mockCanCommit(true);

            // Execute the command
            await doCommit.exec(
              directory: d,
              ggLog: ggLog,
              message: 'my message',
            );

            // Expect didCommit is set to true
            verifyDidCommitIsSet(true);

            // No git commands should be called
            verifyNever(
              () => processWrapper.run(
                'git',
                ['add', '.'],
                workingDirectory: d.path,
              ),
            );
            verifyNever(
              () => processWrapper.run(
                'git',
                ['commit', '-m', 'my message'],
                workingDirectory: d.path,
              ),
            );
          });
        });
      });

      group('should take message from command line', () {
        test('if not provided', () async {
          // Assume not everything is commited yet.
          mockIsCommitted(false);

          // Assume didCommit is not yet set
          mockDidCommitGet(false);
          mockDidCommitSet(true);

          // Assume everything is fine
          mockCanCommit(true);

          // Execute the command
          final runner = CommandRunner<void>('test', 'test');
          runner.addCommand(doCommit);

          await runner.run([
            'commit',
            '--input',
            d.path,
            '-m',
            'my message',
          ]);

          // Expect didCommit is set to true
          verifyDidCommitIsSet(true);
          verifyDidGitAdd();
          verifyDidGitCommit();
        });
      });

      group('should throw', () {
        test('if canCommit throws', () async {
          // Assume not everything is commited yet.
          mockIsCommitted(false);

          // Assume didCommit is not yet set
          mockDidCommitGet(false);
          mockDidCommitSet(true);

          // Assume canCommit throws
          mockCanCommit(false);

          // Execute the command
          expect(
            () => doCommit.exec(
              directory: d,
              ggLog: ggLog,
              message: 'my message',
            ),
            throwsA(isA<Exception>()),
          );

          // Expect didCommit is not set
          verifyNever(
            () => didCommit.set(
              directory: any(named: 'directory'),
              success: true,
            ),
          );

          // No git commands should be called
          verifyNever(
            () => processWrapper.run(
              'git',
              ['add', '.'],
              workingDirectory: d.path,
            ),
          );
          verifyNever(
            () => processWrapper.run(
              'git',
              ['commit', '-m', 'my message'],
              workingDirectory: d.path,
            ),
          );
        });

        test('if »git commit« fails', () async {
          // Assume not everything is commited yet.
          mockIsCommitted(false);

          // Assume didCommit is not yet set
          mockDidCommitGet(false);
          mockDidCommitSet(true);

          // Assume everything is fine
          mockCanCommit(true);

          // Assume git commit fails
          when(
            () => processWrapper.run(
              'git',
              ['commit', '-m', 'my message'],
              workingDirectory: d.path,
            ),
          ).thenAnswer(
            (_) => Future.value(
              ProcessResult(1, 1, 'stdout', 'stderr'),
            ),
          );

          // Execute the command
          late String exception;

          try {
            await doCommit.exec(
              directory: d,
              ggLog: ggLog,
              message: 'my message',
            );
          } catch (e) {
            exception = e.toString();
          }
          expect(exception, contains('git commit failed: stderr'));

          // Expect didCommit is not set
          verifyNever(
            () => didCommit.set(
              directory: any(named: 'directory'),
              success: true,
            ),
          );

          // Expect git add is called
          verifyDidGitAdd();
          verifyDidGitCommit();
        });

        test('if »git add« fails', () async {
          // Assume not everything is commited yet.
          mockIsCommitted(false);

          // Assume didCommit is not yet set
          mockDidCommitGet(false);
          mockDidCommitSet(true);

          // Assume everything is fine
          mockCanCommit(true);

          // Assume git commit fails
          when(
            () => processWrapper.run(
              'git',
              ['add', '.'],
              workingDirectory: d.path,
            ),
          ).thenAnswer(
            (_) => Future.value(
              ProcessResult(1, 1, 'stdout', 'stderr'),
            ),
          );

          // Execute the command
          late String exception;

          try {
            await doCommit.exec(
              directory: d,
              ggLog: ggLog,
              message: 'my message',
            );
          } catch (e) {
            exception = e.toString();
          }
          expect(exception, contains('git add failed: stderr'));

          // Expect didCommit is not set
          verifyNever(
            () => didCommit.set(
              directory: any(named: 'directory'),
              success: true,
            ),
          );

          // Expect git add is called
          verifyDidGitAdd();
        });

        test('if directory is not a git dir', () async {
          final doCommit = DoCommit(
            ggLog: ggLog,
          );

          late String exception;
          try {
            await doCommit.exec(
              directory: d,
              ggLog: ggLog,
              message: 'my message',
            );
          } catch (e) {
            exception = e.toString();
          }

          expect(exception, contains('is not a git repository'));
        });
      });
    });
  });
}
