// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg/gg.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late Directory d;
  final messages = <String>[];
  final ggLog = messages.add;
  late CommandRunner<void> runner;
  late DoCheckout doCheckout;
  late MockIsPushed isPushed;
  late MockGgProcessWrapper processWrapper;

  setUp(() async {
    messages.clear();
    d = await Directory.systemTemp.createTemp();
    registerFallbackValue(d);
    isPushed = MockIsPushed();
    processWrapper = MockGgProcessWrapper();
    doCheckout = DoCheckout(
      ggLog: ggLog,
      isPushed: isPushed,
      processWrapper: processWrapper,
    );
    runner = CommandRunner<void>('gg', 'gg')..addCommand(doCheckout);
  });

  tearDown(() async {
    await d.delete(recursive: true);
  });

  void mockGitCommand(
    List<String> args, {
    int exitCode = 0,
    String stderr = '',
  }) {
    when(
      () => processWrapper.run('git', args, workingDirectory: d.path),
    ).thenAnswer((_) async => ProcessResult(0, exitCode, '', stderr));
  }

  group('DoCheckout', () {
    test('should reset soft when unpushed commits exist', () async {
      when(
        () => isPushed.get(
          directory: d,
          ggLog: ggLog,
          ignoreUnCommittedChanges: true,
        ),
      ).thenAnswer((_) async => false);

      mockGitCommand(['reset', '--soft', 'origin/main']);
      mockGitCommand(['stash']);
      mockGitCommand(['checkout', '-b', 'feat_test']);
      mockGitCommand(['stash', 'apply']);

      await doCheckout.exec(
        directory: d,
        ggLog: ggLog,
        branchName: 'feat_test',
      );

      verify(
        () => isPushed.get(
          directory: d,
          ggLog: ggLog,
          ignoreUnCommittedChanges: true,
        ),
      ).called(1);
      verify(
        () => processWrapper.run('git', [
          'reset',
          '--soft',
          'origin/main',
        ], workingDirectory: d.path),
      ).called(1);
      verify(
        () => processWrapper.run('git', ['stash'], workingDirectory: d.path),
      ).called(1);
      verify(
        () => processWrapper.run('git', [
          'checkout',
          '-b',
          'feat_test',
        ], workingDirectory: d.path),
      ).called(1);
      verify(
        () => processWrapper.run('git', [
          'stash',
          'apply',
        ], workingDirectory: d.path),
      ).called(1);
    });

    test('should skip reset when everything is pushed', () async {
      when(
        () => isPushed.get(
          directory: d,
          ggLog: ggLog,
          ignoreUnCommittedChanges: true,
        ),
      ).thenAnswer((_) async => true);

      mockGitCommand(['stash']);
      mockGitCommand(['checkout', '-b', 'feat_test']);
      mockGitCommand(['stash', 'apply']);

      await doCheckout.exec(
        directory: d,
        ggLog: ggLog,
        branchName: 'feat_test',
      );

      verifyNever(
        () => processWrapper.run('git', [
          'reset',
          '--soft',
          'origin/main',
        ], workingDirectory: d.path),
      );
      verify(
        () => processWrapper.run('git', ['stash'], workingDirectory: d.path),
      ).called(1);
      verify(
        () => processWrapper.run('git', [
          'checkout',
          '-b',
          'feat_test',
        ], workingDirectory: d.path),
      ).called(1);
      verify(
        () => processWrapper.run('git', [
          'stash',
          'apply',
        ], workingDirectory: d.path),
      ).called(1);
    });

    test('should support CLI usage', () async {
      when(
        () => isPushed.get(
          directory: any(named: 'directory'),
          ggLog: ggLog,
          ignoreUnCommittedChanges: true,
        ),
      ).thenAnswer((_) async => true);

      mockGitCommand(['stash']);
      mockGitCommand(['checkout', '-b', 'feat_cli']);
      mockGitCommand(['stash', 'apply']);

      await runner.run(['checkout', '-i', d.path, '-b', 'feat_cli']);

      verify(
        () => processWrapper.run('git', [
          'checkout',
          '-b',
          'feat_cli',
        ], workingDirectory: d.path),
      ).called(1);
    });

    test('should apply stash and rethrow when checkout fails', () async {
      when(
        () => isPushed.get(
          directory: d,
          ggLog: ggLog,
          ignoreUnCommittedChanges: true,
        ),
      ).thenAnswer((_) async => true);

      mockGitCommand(['stash']);
      mockGitCommand(
        ['checkout', '-b', 'feat_test'],
        exitCode: 1,
        stderr: 'Checkout error',
      );
      mockGitCommand(['stash', 'apply']);

      await expectLater(
        () => doCheckout.exec(
          directory: d,
          ggLog: ggLog,
          branchName: 'feat_test',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            'Exception: git checkout -b feat_test failed: Checkout error',
          ),
        ),
      );

      verify(
        () => processWrapper.run('git', ['stash'], workingDirectory: d.path),
      ).called(1);
      verify(
        () => processWrapper.run('git', [
          'checkout',
          '-b',
          'feat_test',
        ], workingDirectory: d.path),
      ).called(1);
      verify(
        () => processWrapper.run('git', [
          'stash',
          'apply',
        ], workingDirectory: d.path),
      ).called(1);
    });

    test('should throw when stash fails', () async {
      when(
        () => isPushed.get(
          directory: d,
          ggLog: ggLog,
          ignoreUnCommittedChanges: true,
        ),
      ).thenAnswer((_) async => true);

      mockGitCommand(['stash'], exitCode: 1, stderr: 'Some error');

      expect(
        () => doCheckout.exec(
          directory: d,
          ggLog: ggLog,
          branchName: 'feat_test',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            'Exception: git stash failed: Some error',
          ),
        ),
      );
    });

    test('should throw when branch name is missing', () async {
      expect(
        () => doCheckout.exec(directory: d, ggLog: ggLog),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            'Exception: Missing branch name. '
                'Run again with --branch-name <branch_name>.',
          ),
        ),
      );
    });
  });
}
