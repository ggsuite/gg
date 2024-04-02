// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg/src/tools/gg_state.dart';
import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
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
  }) : _state = state ?? GgState(ggLog: ggLog) {
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

    // Execute commands.
    for (final command in commands) {
      await command.exec(directory: directory, ggLog: ggLog);
    }

    // Save success
    await _state.writeSuccess(
      directory: directory,
      key: name,
    );
  }

  /// The commands to run
  final List<DirCommand<void>> commands;

  // ######################
  // Private
  // ######################

  final GgState _state;

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
      message: 'Already checked. Nothing to do.',
      ggLog: ggLog,
      useCarriageReturn: false,
    ).logStatus(GgStatusPrinterStatus.success);
  }
}
