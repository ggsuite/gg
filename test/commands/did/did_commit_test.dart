// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/src/commands/did/did_commit.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:gg_log/gg_log.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  final messages = <String>[];
  GgLog ggLog = messages.add;
  late DidCommit commit;

  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    await initGit(d);
    await addAndCommitGitIgnoreFile(d, content: '.check.json');
    await addAndCommitSampleFile(d, fileName: 'pubspec.yaml');
    commit = DidCommit(ggLog: messages.add);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  group('did', () {
    group('Commit', () {
      test('work fine ', () async {
        // Initally the command should return false,
        // because nothing is committed
        expect(await commit.get(directory: d, ggLog: ggLog), isFalse);

        // Let's set a success state
        await commit.set(directory: d, success: true);

        // Now the command should return true
        expect(await commit.get(directory: d, ggLog: ggLog), isTrue);

        // For more details look into "did_command_test.dart"
      });
    });
  });
}
