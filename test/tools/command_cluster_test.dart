// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg/gg.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late Directory dLocal;
  late Directory dRemote;
  final messages = <String>[];
  final ggLog = messages.add;
  late IsCommitted isCommitted;
  late IsPushed isPushed;
  late IsUpgraded isUpgraded;
  late CommitCount commitCount;
  late ModifiedFiles modifiedFiles;
  late List<DirCommand<void>> commands;
  late CommandCluster commandCluster;

  setUp(() async {
    // Init basics
    tmp = await Directory.systemTemp.createTemp();
    dLocal = await initLocalGit(tmp);
    dRemote = await initRemoteGit(tmp);
    messages.clear();

    // Init commands
    isCommitted = MockIsCommitted();
    isPushed = MockIsPushed();
    isUpgraded = MockIsUpgraded();
    commands = [isCommitted, isPushed, isUpgraded];

    // Init command cluster
    commandCluster = CommandCluster(
      ggLog: ggLog,
      commands: commands,
      name: 'my-check',
      description: 'A more detailed description.',
      shortDescription: 'Do all check commands work?',
      stateKey: 'my-check',
    );
    commitCount = CommitCount(ggLog: messages.add);
    modifiedFiles = ModifiedFiles(ggLog: messages.add);

    // Mock the commands
    when(() => isCommitted.exec(directory: dLocal, ggLog: ggLog))
        .thenAnswer((_) async {
      ggLog('isCommitted');
    });
    when(() => isPushed.exec(directory: dLocal, ggLog: ggLog))
        .thenAnswer((_) async {
      ggLog('isPushed');
    });
    when(() => isUpgraded.exec(directory: dLocal, ggLog: ggLog))
        .thenAnswer((_) async {
      ggLog('isUpgraded');
    });
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  group('CommandCluster', () {
    group('exec(directory, log)', () {
      group('with force == false', () {
        test('should not run commands again that were successful before',
            () async {
          // Run the command a first time
          // Should complain about missing commits
          late String exception;
          try {
            await commandCluster.exec(directory: dLocal, ggLog: ggLog);
          } catch (e) {
            exception = e.toString();
          }

          expect(messages[0], contains('Do all check commands work?'));
          expect(
            exception,
            'Exception: There must be at least one commit in the repository.',
          );

          // Make an initial commit
          await addAndCommitSampleFile(dLocal, fileName: 'file1.txt');

          // Run command again
          await commandCluster.exec(directory: dLocal, ggLog: ggLog);
          expect(messages[1], contains('Do all check commands work?'));
          expect(messages[2], 'isCommitted');
          expect(messages[3], 'isPushed');
          expect(messages[4], 'isUpgraded');

          // Run the command a second time.
          // Should not run the commands again,
          // because force is false
          // and the commands were successful before.
          await commandCluster.exec(directory: dLocal, ggLog: ggLog);
          expect(messages[5], contains('Do all check commands work?'));
          expect(
            messages[6],
            '✅ Everything is fine.',
          );
        });
      });

      group('with force == true', () {
        test(
          'should run commands '
          'no matter if they were successful before or not',
          () async {
            await addAndCommitSampleFile(dLocal, fileName: 'file1.txt');

            // Run the command a first time
            await commandCluster.exec(directory: dLocal, ggLog: ggLog);
            expect(messages[0], contains('Do all check commands work?'));
            expect(messages[1], 'isCommitted');
            expect(messages[2], 'isPushed');
            expect(messages[3], 'isUpgraded');

            // Run the command a second first time
            await commandCluster.exec(
              directory: dLocal,
              ggLog: ggLog,
              force: true,
            );
            expect(messages[4], contains('Do all check commands work?'));
            expect(messages[5], 'isCommitted');
            expect(messages[6], 'isPushed');
            expect(messages[7], 'isUpgraded');
          },
        );
      });

      group('should ammend changes to .gg.json to the last commit', () {
        test('when previous changes were not already pushed', () async {
          // Let's create an inital commit
          await addAndCommitSampleFile(dLocal, fileName: 'file1.txt');

          // Check the inital commit count
          final initialCommitCount = await commitCount.get(
            directory: dLocal,
            ggLog: ggLog,
          );
          expect(initialCommitCount, 1);

          // file1.txt should be shown as modified in the last commit
          expect(
            await modifiedFiles.get(
              directory: dLocal,
              ggLog: ggLog,
              force: true,
            ),
            ['file1.txt'],
          );

          // Run the command a first time
          await commandCluster.exec(directory: dLocal, ggLog: ggLog);
          expect(messages[0], contains('Do all check commands work?'));
          expect(messages[1], 'isCommitted');
          expect(messages[2], 'isPushed');
          expect(messages[3], 'isUpgraded');

          // Because we have not pushed the changes yet,
          // changes to gg.json should be ammended to the last commit

          // - i.e. commit count has not changed
          final commitCount0 = await commitCount.get(
            directory: dLocal,
            ggLog: ggLog,
          );
          expect(commitCount0, 1);

          // - i.e. file1.txt should be shown as modified in the last commit
          expect(
            await modifiedFiles.get(
              directory: dLocal,
              ggLog: ggLog,
              force: true,
            ),
            ['.gg.json', 'file1.txt'],
          );
        });
      });

      group('should create a new commit', () {
        test('when previous changes were already pushed', () async {
          // Let's create an inital commit
          await addAndCommitSampleFile(dLocal, fileName: 'file1.txt');

          // Let's connect the local and remote repositories
          await addRemoteToLocal(local: dLocal, remote: dRemote);

          // Check the inital commit count
          final initialCommitCount = await commitCount.get(
            directory: dLocal,
            ggLog: ggLog,
          );
          expect(initialCommitCount, 1);

          // file1.txt should be shown as modified in the last commit
          expect(
            await modifiedFiles.get(
              directory: dLocal,
              ggLog: ggLog,
              force: true,
            ),
            ['file1.txt'],
          );

          // Push the changes
          await Process.run(
            'git',
            ['push'],
            workingDirectory: dLocal.path,
          );

          // Run the command a first time
          await commandCluster.exec(directory: dLocal, ggLog: ggLog);
          expect(messages[0], contains('Do all check commands work?'));
          expect(messages[1], 'Everything is pushed.');
          expect(messages[2], 'isCommitted');
          expect(messages[3], 'isPushed');
          expect(messages[4], 'isUpgraded');

          // Because we have pushed the changes already,
          // changes to gg.json should be commited as a new commit

          // - i.e. commit count has changed
          final commitCount0 = await commitCount.get(
            directory: dLocal,
            ggLog: ggLog,
          );
          expect(commitCount0, 2);

          // - i.e. only .gg.json should be shown as modified in the last commit
          expect(
            await modifiedFiles.get(
              directory: dLocal,
              ggLog: ggLog,
              force: true,
            ),
            ['.gg.json'],
          );

          // Executing the cluster again should not change anything
          await commandCluster.exec(directory: dLocal, ggLog: ggLog);
          expect(messages[5], contains('Do all check commands work?'));
          expect(messages[6], '✅ Everything is fine.');
        });
      });
    });
  });
}
