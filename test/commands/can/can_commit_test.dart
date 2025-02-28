// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_test/gg_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// .............................................................................
void main() {
  late Directory d;
  late Checks commands;
  final messages = <String>[];
  late CanCommit commit;

  // ...........................................................................
  void mockCommands() {
    when(
      () => commands.analyze.exec(directory: d, ggLog: messages.add),
    ).thenAnswer((_) async {
      messages.add('did analyze');
    });
    when(
      () => commands.format.exec(directory: d, ggLog: messages.add),
    ).thenAnswer((_) async {
      messages.add('did format');
    });
    when(
      () => commands.tests.exec(directory: d, ggLog: messages.add),
    ).thenAnswer((_) async {
      messages.add('did cover');
    });
  }

  // ...........................................................................
  setUp(() async {
    commands = Checks(
      ggLog: messages.add,
      analyze: MockAnalyze(),
      format: MockFormat(),
      tests: MockTests(),
    );

    commit = CanCommit(ggLog: messages.add, checks: commands);
    d = Directory.systemTemp.createTempSync();
    await initGit(d);
    registerFallbackValue(d);
    mockCommands();
    messages.clear();
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('Can', () {
    group('constructor', () {
      test('with defaults', () {
        final c = CanCommit(ggLog: messages.add);
        expect(c.name, 'commit');
        expect(c.description, 'Are the last changes ready for »git commit«?');
      });
    });

    group('Commit', () {
      group('run(directory)', () {
        test('should run analyze, format and coverage', () async {
          await addAndCommitSampleFile(d);
          await commit.exec(directory: d, ggLog: messages.add);
          expect(messages[0], yellow('Can commit?'));
          expect(messages[1], 'did analyze');
          expect(messages[2], 'did format');
          expect(messages[3], 'did cover');
        });
      });
    });
  });

  group('MockCanCommit', () {
    group('mockExec', () {
      group('should mock exec', () {
        Future<void> runTest({required bool useGgLog}) async {
          final canCommit = MockCanCommit();
          canCommit.mockExec(
            result: null,
            directory: d, // <-- ggLog
            ggLog: useGgLog ? messages.add : null,
            force: true,
            saveState: false,
          );

          await canCommit.exec(
            directory: d,
            ggLog: messages.add,
            force: true,
            saveState: false,
          );
          expect(messages[0], contains('✅ CanCommit'));
        }

        test('with ggLog', () async {
          await runTest(useGgLog: true);
        });

        test('with directory == null', () async {
          await runTest(useGgLog: false);
        });
      });
    });

    group('mockGet', () {
      group('should mock get', () {
        Future<void> runTest({required bool useGgLog}) async {
          final canCommit = MockCanCommit();
          canCommit.mockGet(
            result: null,
            directory: d,
            ggLog: useGgLog ? messages.add : null, // <-- ggLog
            force: true,
            saveState: false,
          );

          await canCommit.get(
            directory: d,
            ggLog: messages.add,
            force: true,
            saveState: false,
          );
          expect(messages[0], contains('✅ CanCommit'));
        }

        test('with ggLog', () async {
          await runTest(useGgLog: true);
        });

        test('with directory == null', () async {
          await runTest(useGgLog: false);
        });
      });
    });
  });
}
