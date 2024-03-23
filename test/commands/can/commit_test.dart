// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_check/gg_check.dart';
import 'package:gg_check/src/commands/can/commit.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// .............................................................................
void main() {
  late Directory d;
  late Checks commands;
  final messages = <String>[];
  late Commit commit;

  // ...........................................................................
  void mockCommands() {
    when(() => commands.analyze.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('did analyze');
    });
    when(() => commands.format.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('did format');
    });
    when(() => commands.coverage.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('did cover');
    });
  }

  // ...........................................................................
  setUp(() {
    commands = Checks(
      ggLog: messages.add,
      analyze: MockAnalyze(),
      format: MockFormat(),
      coverage: MockCoverage(),
    );

    commit = Commit(ggLog: messages.add, checks: commands);
    d = Directory.systemTemp.createTempSync();
    mockCommands();
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('Can', () {
    group('constructor', () {
      test('with defaults', () {
        final c = Commit(ggLog: messages.add);
        expect(c.name, 'commit');
        expect(c.description, 'Checks if code is ready to commit.');
      });
    });

    group('Commit', () {
      group('run(directory)', () {
        test('should run analyze, format and coverage', () async {
          await commit.exec(directory: d, ggLog: messages.add);
          expect(messages[0], yellow('Can commit?'));
          expect(messages[1], 'did analyze');
          expect(messages[2], 'did format');
          expect(messages[3], 'did cover');
        });
      });
    });
  });
}
