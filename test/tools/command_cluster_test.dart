// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_check/gg_check.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_publish/gg_publish.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  final messages = <String>[];
  late IsCommitted isCommitted;
  late IsPushed isPushed;
  late IsUpgraded isUpgraded;
  late List<DirCommand<void>> commands;
  late CommandCluster commandCluster;

  setUp(() {
    // Init basics
    d = Directory.systemTemp.createTempSync();
    messages.clear();

    // Init commands
    isCommitted = MockIsCommitted();
    isPushed = MockIsPushed();
    isUpgraded = MockIsUpgraded();
    commands = [isCommitted, isPushed, isUpgraded];

    // Init command cluster
    commandCluster = CommandCluster(
      ggLog: messages.add,
      commands: commands,
      name: 'my-check',
      description: 'A more detailed description.',
      shortDescription: 'Do all check commands work?',
    );

    // Mock the commands
    when(() => isCommitted.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {});
    when(() => isPushed.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {});
    when(() => isUpgraded.exec(directory: d, ggLog: messages.add))
        .thenAnswer((_) async {});
  });

  tearDown(() {
    d.deleteSync(recursive: true);
  });

  group('CommandCluster', () {
    group('run', () {
      test('should run all commands', () {
        expect(commandCluster, isNotNull);
      });
    });
  });
}
