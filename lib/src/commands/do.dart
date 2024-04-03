// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg/gg.dart';
import 'package:gg_log/gg_log.dart';

// .............................................................................
/// Various checks for the source code
class Do extends Command<void> {
  /// Constructor
  Do({
    required this.ggLog,
    DepsOfDo? deps,
  }) {
    deps ??= DepsOfDo(ggLog: ggLog);
    _initSubCommands(deps);
  }

  /// The log function
  final GgLog ggLog;

  /// Then name of the command
  @override
  final name = 'do';

  /// The description of the command
  @override
  final description = 'Provide actions or commit, push, publish.';

  // ...........................................................................
  void _initSubCommands(DepsOfDo deps) {
    addSubcommand(deps.doCommit);
    addSubcommand(deps.doPush);
  }
}

// .............................................................................
/// Dependencies for the check command
class DepsOfDo {
  /// Constructor
  DepsOfDo({
    required this.ggLog,
    DoCommit? doCommit,
    DoPush? doPush,
  })  : doCommit = doCommit ?? DoCommit(ggLog: ggLog),
        doPush = doPush ?? DoPush(ggLog: ggLog);

  /// The log function
  final GgLog ggLog;

  /// The can commit command
  final DoCommit doCommit;

  /// The can commit command
  final DoPush doPush;
}
