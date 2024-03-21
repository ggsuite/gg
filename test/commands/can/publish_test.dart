// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_check/gg_check.dart';
import 'package:gg_check/src/commands/can/publish.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_version/gg_version.dart';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// .............................................................................
void main() {
  late Directory d;
  late CheckCommands commands;
  final messages = <String>[];
  late Publish publish;

  // ...........................................................................
  void mockCommands() {
    when(() => commands.isPushed.run(directory: d)).thenAnswer((_) async {
      messages.add('isPushed');
    });
    when(() => commands.isVersioned.run(directory: d)).thenAnswer((_) async {
      messages.add('isVersioned');
    });
    when(() => commands.pana.run(directory: d)).thenAnswer((_) async {
      messages.add('pana');
    });
  }

  // ...........................................................................
  setUp(() {
    commands = CheckCommands(
      log: messages.add,
      isPushed: MockIsPushed(),
      isVersioned: MockIsVersioned(),
      pana: MockPana(),
    );

    publish = Publish(log: messages.add, checkCommands: commands);
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
        final c = Publish(log: messages.add);
        expect(c.name, 'publish');
        expect(c.description, 'Checks if code is ready to be published.');
      });
    });

    group('Publish', () {
      group('run(directory)', () {
        test('should check if everything is upgraded and commited', () async {
          await publish.run(directory: d);
          expect(messages[0], 'isPushed');
          expect(messages[1], 'isVersioned');
          expect(messages[2], 'pana');
        });
      });
    });
  });
}
