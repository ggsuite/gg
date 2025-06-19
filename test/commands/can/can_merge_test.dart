// @license
// Copyright (c) 2025 Gran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';
import 'package:gg/gg.dart';
import 'package:gg_git/gg_git_test_helpers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  late Directory dRemote;
  late CanMerge canMerge;
  final messages = <String>[];
  final ggLog = messages.add;

  Future<void> runGit(
    List<String> args, {
    required Directory dir,
    bool throwOnError = true,
  }) async {
    final result = await Process.run('git', args, workingDirectory: dir.path);
    if (throwOnError && result.exitCode != 0) {
      throw Exception('git ${args.join(' ')}: ${result.stderr}');
    }
  }

  Future<void> pushWithUpstream(Directory repo, String branch) async {
    await runGit(['push', '--set-upstream', 'origin', branch], dir: repo);
  }

  setUp(() async {
    d = await Directory.systemTemp.createTemp('merge_test');

    dRemote = await initTestDir();
    await initRemoteGit(dRemote);
    await initGit(d);
    await addRemoteToLocal(local: d, remote: dRemote);
    await addAndCommitSampleFile(
      d,
      fileName: 'pubspec.yaml',
      content: 'name: merge_test\nversion: 1.0.0',
    );
    await pushWithUpstream(d, 'main');

    await createBranch(d, 'feat');
    await addAndCommitSampleFile(
      d,
      fileName: 'feat.txt',
      content: 'feat changes',
    );
    await pushWithUpstream(d, 'feat');

    registerFallbackValue(d);

    canMerge = CanMerge(ggLog: ggLog);
    messages.clear();
  });

  tearDown(() async {
    await d.delete(recursive: true);
    await dRemote.delete(recursive: true);
  });

  group('CanMerge', () {
    test('exec() runs all subcommands and logs status', () async {
      await canMerge.exec(directory: d, ggLog: ggLog);
      expect(messages[0], contains('Can merge?'));
      expect(messages, contains('✅ All merge conditions fulfilled.'));
    });

    test('default constructor sets name and description', () {
      final canMerge = CanMerge(ggLog: ggLog);
      expect(canMerge.name, 'merge');
      expect(
        canMerge.description,
        'Are all preconditions for merging main fulfilled?',
      );
    });
  });
}
