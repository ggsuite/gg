// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/src/commands/can/can_commit.dart';
import 'package:gg/src/tools/gg_state.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';

/// Does a commit of the current directory.
class DoCommit extends DirCommand<void> {
  /// Constructor
  DoCommit({
    required super.ggLog,
    super.name = 'commit',
    super.description = 'Commits the current directory.',
    IsCommitted? isCommitted,
    CanCommit? canCommit,
    GgProcessWrapper processWrapper = const GgProcessWrapper(),
    GgState? state,
  })  : _processWrapper = processWrapper,
        _isGitCommitted = isCommitted ?? IsCommitted(ggLog: ggLog),
        _canCommit = canCommit ?? CanCommit(ggLog: ggLog),
        state = state ?? GgState(ggLog: ggLog) {
    _addParam();
  }

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
    String? message,
  }) async {
    // Does directory exist?
    await check(directory: directory);

    // Is everything committed?
    final isCommittedViaGit = await _isGitCommitted.get(
      directory: directory,
      ggLog: ggLog,
    );

    // Is didCommit already set?
    if (isCommittedViaGit) {
      final isDone = await state.readSuccess(
        directory: directory,
        key: stateKey,
        ggLog: ggLog,
      );

      if (isDone) {
        ggLog(yellow('Already checked and committed.'));
        return;
      }
    }

    // Is everything fine?
    await _canCommit.exec(
      directory: directory,
      ggLog: ggLog,
    );

    // Execute the commit
    if (!isCommittedViaGit) {
      message ??= _messageFromArgs();
      await gitAddAndCommit(directory: directory, message: message);
      ggLog(yellow('Checks successful. Commit successful.'));
    } else {
      ggLog(yellow('Checks successful. Nothing to commit.'));
    }

    // Save the state
    await state.writeSuccess(
      directory: directory,
      key: stateKey,
    );
  }

  /// The state used to save the state of the command
  final GgState state;

  /// The key used to save the state of the command
  final String stateKey = 'doCommit';

  // ...........................................................................
  /// Adds and commits the current directory.
  Future<void> gitAddAndCommit({
    required Directory directory,
    required String message,
  }) async {
    await _gitAdd(directory, message);
    await _gitCommit(directory: directory, message: message);
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  final GgProcessWrapper _processWrapper;
  final IsCommitted _isGitCommitted;
  final CanCommit _canCommit;

  // ...........................................................................
  void _addParam() {
    argParser.addOption(
      'message',
      abbr: 'm',
      help: 'The message for the commit.',
      mandatory: true,
    );
  }

  // ...........................................................................
  Future<void> _gitAdd(Directory directory, String message) async {
    final result = await _processWrapper.run(
      'git',
      ['add', '.'],
      workingDirectory: directory.path,
    );

    if (result.exitCode != 0) {
      throw Exception('git add failed: ${result.stderr}');
    }
  }

  // ...........................................................................
  /// Executes the git commit command.
  Future<void> _gitCommit({
    required Directory directory,
    required String message,
  }) async {
    final result = await _processWrapper.run(
      'git',
      ['commit', '-m', message],
      workingDirectory: directory.path,
    );

    if (result.exitCode != 0) {
      throw Exception('git commit failed: ${result.stderr}');
    }
  }

  // ...........................................................................
  String _messageFromArgs() {
    try {
      final message = argResults!['message'] as String;
      return message;
    } catch (e) {
      throw Exception(
        red('Message missing.\n') +
            darkGray('Run command again with ') +
            yellow('--message ') +
            blue('"your message"'),
      );
    }
  }
}

// .............................................................................
/// Mock for [DoCommit].
class MockDoCommmit extends Mock implements DoCommit {}
