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
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  final messages = <String>[];
  final ggLog = messages.add;
  late IsCommitted isCommitted;
  late IsPushed isPushed;
  late IsUpgraded isUpgraded;

  late List<DirCommand<void>> commands;
  late CommandCluster commandCluster;

  setUp(() async {
    // Init basics
    messages.clear();
    d = Directory.systemTemp.createTempSync();
    await initGit(d);

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

    // Mock the commands
    when(() => isCommitted.exec(directory: d, ggLog: ggLog))
        .thenAnswer((_) async {
      ggLog('isCommitted');
      return true;
    });
    when(() => isPushed.exec(directory: d, ggLog: ggLog)).thenAnswer((_) async {
      ggLog('isPushed');
      return true;
    });
    when(() => isUpgraded.exec(directory: d, ggLog: ggLog))
        .thenAnswer((_) async {
      ggLog('isUpgraded');
      return true;
    });
  });

  tearDown(() async {
    await d.delete(recursive: true);
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
            await commandCluster.exec(directory: d, ggLog: ggLog);
          } catch (e) {
            exception = e.toString();
          }

          expect(messages[0], contains('Do all check commands work?'));
          expect(messages[1], 'isCommitted');
          expect(messages[2], 'isPushed');
          expect(messages[3], 'isUpgraded');

          expect(
            exception,
            'Exception: There must be at least one commit in the repository.',
          );

          // Make an initial commit
          await addAndCommitSampleFile(d, fileName: 'file1.txt');

          // Run command again
          await commandCluster.exec(directory: d, ggLog: ggLog);
          expect(messages[4], contains('Do all check commands work?'));
          expect(messages[5], 'isCommitted');
          expect(messages[6], 'isPushed');
          expect(messages[7], 'isUpgraded');

          // Run the command a second time.
          // Should not run the commands again,
          // because force is false
          // and the commands were successful before.
          await commandCluster.exec(directory: d, ggLog: ggLog);
          expect(messages[8], contains('Do all check commands work?'));
          expect(
            messages[9],
            '✅ Everything is fine.',
          );
        });
      });

      group('with force == true', () {
        test(
          'should run commands '
          'no matter if they were successful before or not',
          () async {
            await addAndCommitSampleFile(d, fileName: 'file1.txt');

            // Run the command a first time
            await commandCluster.exec(directory: d, ggLog: ggLog);
            expect(messages[0], contains('Do all check commands work?'));
            expect(messages[1], 'isCommitted');
            expect(messages[2], 'isPushed');
            expect(messages[3], 'isUpgraded');

            // Run the command a second first time
            await commandCluster.exec(
              directory: d,
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

      group('with save-state == true or (false)', () {
        test('should (not) save the success state', () async {
          await addAndCommitSampleFile(d, fileName: 'file1.txt');

          final ggJson = await File(join(d.path, '.gg.json')).create();
          final ggJsonBefore = await ggJson.readAsString();

          // Run the command with save-state == false
          await commandCluster.exec(
            directory: d,
            ggLog: ggLog,
            force: true,
            saveState: false,
          );

          // State should not be saved
          final ggJsonAfterWithoutSave = await ggJson.readAsString();
          expect(ggJsonAfterWithoutSave, ggJsonBefore);

          // Run the command with save-state == true
          await commandCluster.exec(
            directory: d,
            ggLog: ggLog,
            force: true,
            saveState: true,
          );

          // State should be saved
          final ggJsonAfterWithSave = await ggJson.readAsString();
          expect(ggJsonBefore, isNot(ggJsonAfterWithSave));
        });
      });
    });
  });
}
