// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_check/gg_check.dart';
import 'package:gg_check/src/commands/can/celebrate.dart';
import 'package:gg_publish/gg_publish.dart';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// .............................................................................
void main() {
  late Directory d;
  late Checks commands;
  final messages = <String>[];
  late Celebrate celebrate;

  // ...........................................................................
  void mockCommands() {
    when(() => commands.isPublished.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('isPublished');
    });
  }

  // ...........................................................................
  setUp(() {
    commands = Checks(
      ggLog: messages.add,
      isPublished: MockIsPublished(),
    );

    celebrate = Celebrate(ggLog: messages.add, checkCommands: commands);
    d = Directory.systemTemp.createTempSync();
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
          final c = Celebrate(ggLog: messages.add);
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
