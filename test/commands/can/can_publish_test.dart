// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg/src/commands/can/can_publish.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_version/gg_version.dart';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// .............................................................................
void main() {
  late Directory d;
  late Checks commands;
  final messages = <String>[];
  late CanPublish publish;

  // ...........................................................................
  void mockCommands() {
    when(() => commands.isPushed.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('isPushed');
    });
    when(() => commands.isVersioned.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('isVersioned');
    });
    when(() => commands.pana.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {
      messages.add('pana');
    });
  }

  // ...........................................................................
  setUp(() {
    commands = Checks(
      ggLog: messages.add,
      isPushed: MockIsPushed(),
      isVersioned: MockIsVersioned(),
      pana: MockPana(),
    );

    publish = CanPublish(ggLog: messages.add, checks: commands);
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
        final c = CanPublish(ggLog: messages.add);
        expect(c.name, 'publish');
        expect(c.description, 'Checks if code is ready to be published.');
      });
    });

    group('Publish', () {
      group('run(directory)', () {
        test('should check if everything is upgraded and commited', () async {
          await publish.exec(directory: d, ggLog: messages.add);
          expect(messages[1], 'isPushed');
          expect(messages[2], 'isVersioned');
          expect(messages[3], 'pana');
        });
      });
    });
  });
}
