// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/gg.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_status_printer/gg_status_printer.dart';

/// Checks out a new branch while preserving local changes.
class DoCheckout extends DirCommand<void> {
  /// Constructor.
  DoCheckout({
    required super.ggLog,
    super.name = 'checkout',
    super.description = 'Checks out a new branch and reapplies local changes.',
    CanCheckout? canCheckout,
    IsPushed? isPushed,
    GgProcessWrapper processWrapper = const GgProcessWrapper(),
    // coverage:ignore-start
  }) : _canCheckout = canCheckout ?? CanCheckout(ggLog: ggLog),
       _isPushed = isPushed ?? IsPushed(ggLog: ggLog),
       _processWrapper = processWrapper {
    // coverage:ignore-end
    _addArgs();
  }

  final CanCheckout _canCheckout;
  final IsPushed _isPushed;
  final GgProcessWrapper _processWrapper;

  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
    String? branchName,
  }) => get(directory: directory, ggLog: ggLog, branchName: branchName);

  @override
  Future<void> get({
    required Directory directory,
    required GgLog ggLog,
    String? branchName,
  }) async {
    await check(directory: directory);
    branchName ??= _branchNameFromArgs();

    await _canCheckout.exec(directory: directory, ggLog: ggLog);

    await GgStatusPrinter<void>(
      message: 'stash changes and do checkout',
      ggLog: ggLog,
    ).logTask(
      task: () async {
        await _stashChangesAndCheckout(
          directory: directory,
          ggLog: ggLog,
          branchName: branchName!,
        );
      },
      success: (_) => true,
    );
  }

  /// Adds CLI arguments for the command.
  void _addArgs() {
    argParser.addOption(
      'branch-name',
      abbr: 'b',
      help: 'The name of the branch to create and check out.',
    );
  }

  /// Returns the branch name from CLI arguments or throws if it is missing.
  String _branchNameFromArgs() {
    final branchName = argResults?['branch-name'] as String? ?? '';
    if (branchName.isEmpty) {
      throw Exception(
        'Missing branch name. Run again with --branch-name <branch_name>.',
      );
    }

    return branchName;
  }

  /// Stashes local changes, performs the checkout, and reapplies the stash.
  Future<void> _stashChangesAndCheckout({
    required Directory directory,
    required GgLog ggLog,
    required String branchName,
  }) async {
    final everythingIsPushed = await _isPushed.get(
      directory: directory,
      ggLog: ggLog,
      ignoreUnCommittedChanges: true,
    );

    if (!everythingIsPushed) {
      await _runGitCommand(
        directory: directory,
        args: ['reset', '--soft', 'origin/main'],
        errorMessage: 'git reset --soft origin/main failed',
      );
    }

    await _runGitCommand(
      directory: directory,
      args: ['stash'],
      errorMessage: 'git stash failed',
    );

    try {
      await _runGitCommand(
        directory: directory,
        args: ['checkout', '-b', branchName],
        errorMessage: 'git checkout -b $branchName failed',
      );
    } catch (error) {
      await _runGitCommand(
        directory: directory,
        args: ['stash', 'apply'],
        errorMessage: 'git stash apply failed',
      );
      rethrow;
    }

    await _runGitCommand(
      directory: directory,
      args: ['stash', 'apply'],
      errorMessage: 'git stash apply failed',
    );
  }

  /// Executes a git command and throws when it fails.
  Future<void> _runGitCommand({
    required Directory directory,
    required List<String> args,
    required String errorMessage,
  }) async {
    final result = await _processWrapper.run(
      'git',
      args,
      workingDirectory: directory.path,
    );

    if (result.exitCode != 0) {
      throw Exception('$errorMessage: ${result.stderr}');
    }
  }
}

/// Mock for [DoCheckout].
class MockDoCheckout extends MockDirCommand<void> implements DoCheckout {}
