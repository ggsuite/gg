// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg/src/commands/can/can_celebrate.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_publish/gg_publish.dart';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// .............................................................................
void main() {
  late Directory d;
  late Checks commands;
  final messages = <String>[];
  late CanCelebrate celebrate;

  // ...........................................................................
  void mockCommands() {
    when(() => commands.isPublished.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('isPublished');
    });
  }

  // ...........................................................................
  setUp(() async {
    commands = Checks(
      ggLog: messages.add,
      isPublished: MockIsPublished(),
    );

    celebrate = CanCelebrate(ggLog: messages.add, checkCommands: commands);
    d = Directory.systemTemp.createTempSync();
    await initGit(d);
    mockCommands();
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('Can', () {
    group('Celebrate', () {
      group('constructor', () {
        test('with defaults', () {
          final c = CanCelebrate(ggLog: messages.add);
          expect(c.name, 'celebrate');
          expect(
            c.description,
            'Checks if everything is done and we can start the party.',
          );
        });
      });
      group('run(directory)', () {
        test(
            'should check if is done, '
            'i.e. everything is checked, pushed and published', () async {
          await celebrate.exec(directory: d, ggLog: messages.add);
          expect(messages[0], contains('Can celebrate?'));
          expect(messages[1], 'isPublished');
        });
      });
    });
  });
}
