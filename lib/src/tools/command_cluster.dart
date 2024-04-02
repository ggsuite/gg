// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/src/tools/gg_state.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_status_printer/gg_status_printer.dart';

/// A cluster of commands that is run in sequence
class CommandCluster extends DirCommand<void> {
  /// Constructor
  CommandCluster({
    required super.ggLog,
    required this.commands,
    required super.name,
    required super.description,
    required this.shortDescription,
    GgState? state,
    IsPushed? isPushed,
    IsCommitted? isCommitted,
    ModifiedFiles? modifiedFiles,
    Commit? commit,
    HeadMessage? headMessage,
    HasRemote? hasRemote,
    CommitCount? commitCount,
  })  : _state = state ?? GgState(ggLog: ggLog),
        _isPushed = isPushed ?? IsPushed(ggLog: ggLog),
        _isCommitted = isCommitted ?? IsCommitted(ggLog: ggLog),
        _modifiedFiles = modifiedFiles ?? ModifiedFiles(ggLog: ggLog),
        _commit = commit ?? Commit(ggLog: ggLog),
        _headMessage = headMessage ?? HeadMessage(ggLog: ggLog),
        _hasRemote = hasRemote ?? HasRemote(ggLog: ggLog),
        _commitCount = commitCount ?? CommitCount(ggLog: ggLog) {
    _addArgs();
  }

  // ...........................................................................
  /// The short description printed at the beginning of each command
  final String shortDescription;

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
    bool? force,
  }) async {
    ggLog(yellow(shortDescription));

    // Was successful before? Do nothing.
    if (!await _actionIsNeeded(directory, ggLog, force)) {
      _printAlreadyDoneSuccess(ggLog);
      return;
    }

    // Nothing committed so far? Do nothing.
    await _checkCommitsAvailable(directory, ggLog);

    // Remember if everything is committed and pushed
    final everythingWasCommitted = await _isCommitted.get(
      directory: directory,
      ggLog: ggLog,
    );

    final hasRemote = await _hasRemote.get(
      directory: directory,
      ggLog: ggLog,
    );

    final everythingWasPushed = everythingWasCommitted &&
        hasRemote &&
        await _isPushed.get(
          directory: directory,
          ggLog: ggLog,
        );

    final headMessage = everythingWasCommitted
        ? await _headMessage.get(directory: directory, ggLog: ggLog)
        : '';

    // Execute commands.
    for (final command in commands) {
      await command.exec(directory: directory, ggLog: ggLog);
    }

    // Save success
    await _state.writeSuccess(
      directory: directory,
      key: name,
    );

    // ....................................................
    // If not everything was committed before, return here.
    //  gg.json will be committed with the next commit.
    if (!everythingWasCommitted) {
      return;
    }

    // Check if .gg.json has changed.
    // If not, return here.
    final modifiedFiles = await _modifiedFiles.get(
      directory: directory,
      ggLog: ggLog,
    );
    if (modifiedFiles.isEmpty) {
      return;
    }

    // ...........................
    // To have a clean git history,
    // we will ammend changes to .gg.json to the last commit.
    // - If everything was committed and pushed, create a new commit
    // - If everything was committed but not pushed, ammend to last commit
    final message = everythingWasPushed ? 'Update .gg.json' : headMessage;

    await _commit.commit(
      directory: directory,
      ggLog: ggLog,
      doStage: true,
      message: message,
      ammend: !everythingWasPushed,
    );
  }

  /// The commands to run
  final List<DirCommand<void>> commands;

  // ######################
  // Private
  // ######################

  final GgState _state;
  final IsPushed _isPushed;
  final IsCommitted _isCommitted;
  final ModifiedFiles _modifiedFiles;
  final Commit _commit;
  final HeadMessage _headMessage;
  final HasRemote _hasRemote;
  final CommitCount _commitCount;

  // ...........................................................................
  void _addArgs() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Executes the commands also if they were successful before.',
      defaultsTo: false,
    );
  }

  // ...........................................................................
  Future<bool> _wasSuccessfulBefore(Directory directory, GgLog ggLog) async {
    return await _state.readSuccess(
      directory: directory,
      key: name,
      ggLog: ggLog,
    );
  }

  // ...........................................................................
  Future<bool> _actionIsNeeded(
    Directory directory,
    GgLog ggLog,
    bool? force,
  ) async {
    force = force ?? argResults?['force'] as bool? ?? false;
    final needsAction =
        force || !(await _wasSuccessfulBefore(directory, ggLog));
    return needsAction;
  }

  // ...........................................................................
  void _printAlreadyDoneSuccess(GgLog ggLog) {
    GgStatusPrinter<void>(
      message: 'Everything is fine.',
      ggLog: ggLog,
      useCarriageReturn: false,
    ).logStatus(GgStatusPrinterStatus.success);
  }

  // ...........................................................................
  Future<void> _checkCommitsAvailable(Directory directory, GgLog ggLog) async {
    final commitCount = await _commitCount.get(
      directory: directory,
      ggLog: ggLog,
    );
    if (commitCount == 0) {
      throw Exception('There must be at least one commit in the repository.');
    }
  }
}
