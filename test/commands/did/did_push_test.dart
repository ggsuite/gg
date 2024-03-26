// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/src/commands/did/did_push.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_log/gg_log.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  final messages = <String>[];
  GgLog ggLog = messages.add;
  late DidPush didPush;

  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    await initGit(d);
    await addAndCommitGitIgnoreFile(d, content: '.check.json');
    await addAndCommitSampleFile(d, fileName: 'pubspec.yaml');
    didPush = DidPush(ggLog: messages.add);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('did', () {
    group('Push', () {
      test('work fine ', () async {
        // Initally the command should throw, because the predecessor
        // "did/commit" is not yet executed.
        late String exception;
        try {
          await didPush.exec(directory: d, ggLog: ggLog);
        } catch (e) {
          exception = e.toString();
        }
        expect(exception, contains(red('Did run »gg do commit«?')));

        // Let's successfully commit
        final didCommit = didPush.predecessors.first;
        await didCommit.set(directory: d, success: true);

        // It should not throw anymore but return false,
        // because we did not push yet
        expect(await didPush.get(directory: d, ggLog: ggLog), isFalse);

        // Let's push
        await didPush.set(directory: d, success: true);

        // Now the command should return true
        expect(await didPush.get(directory: d, ggLog: ggLog), isTrue);

        // For more details look into "did_command_test.dart"
      });
    });
  });
}
