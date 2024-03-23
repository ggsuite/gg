// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg/src/commands/can/push.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_publish/gg_publish.dart';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// .............................................................................
void main() {
  late Directory d;
  late Checks commands;
  final messages = <String>[];
  late Push push;

  // ...........................................................................
  void mockCommands() {
    when(() => commands.isCommitted.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('did commit');
    });
    when(() => commands.isUpgraded.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('did upgrade');
    });
  }

  // ...........................................................................
  setUp(() {
    commands = Checks(
      ggLog: messages.add,
      isCommitted: MockIsCommitted(),
      isUpgraded: MockIsUpgraded(),
    );

    push = Push(ggLog: messages.add, checkCommands: commands);
    d = Directory.systemTemp.createTempSync();
    mockCommands();
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('Can', () {
    group('Push', () {
      group('constructor', () {
        test('with defaults', () {
          final c = Push(ggLog: messages.add);
          expect(c.name, 'push');
          expect(c.description, 'Checks if code is ready to push.');
        });
      });
      group('run(directory)', () {
        test('should check if everything is upgraded and commited', () async {
          await push.exec(directory: d, ggLog: messages.add);
          expect(messages[0], contains('Can push?'));
          expect(messages[1], 'did upgrade');
          expect(messages[2], 'did commit');
        });
      });
    });
  });
}
