// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg/src/commands/can/can_publish.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// .............................................................................
void main() {
  late Directory d;
  final messages = <String>[];
  final ggLog = messages.add;
  late CanPublish canPublish;

  // ...........................................................................
  late Pana pana;
  late DidCommit didCommit;
  late IsVersionPrepared isVersionPrepared;

  // ...........................................................................
  void mockCommands() {
    when(() => pana.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('pana');
    });
    when(() => didCommit.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('didCommit');
    });
    when(() => isVersionPrepared.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('isVersionPrepared');
    });
  }

  // ...........................................................................
  setUp(() async {
    pana = MockPana();
    didCommit = MockDidCommit();
    isVersionPrepared = MockIsVersionPrepared();

    canPublish = CanPublish(
      ggLog: ggLog,
      pana: pana,
      didCommit: didCommit,
      isVersionPrepared: isVersionPrepared,
    );
    d = Directory.systemTemp.createTempSync();
    await initGit(d);
    await addAndCommitSampleFile(d);
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('CanPublish', () {
    group('run()', () {
      test('should run the sub commands', () async {
        mockCommands();
        await canPublish.exec(directory: d, ggLog: ggLog);
        expect(messages[0], yellow('Can publish?'));
        expect(messages[1], 'isVersionPrepared');
        expect(messages[2], 'didCommit');
        expect(messages[3], 'pana');
      });
    });

    test('should have a code coverage of 100%', () {
      expect(
        CanPublish(ggLog: ggLog),
        isNotNull,
      );
    });
  });
}
