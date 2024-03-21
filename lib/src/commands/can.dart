// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_check/src/commands/can/commit.dart';
import 'package:gg_check/src/commands/can/publish.dart';
import 'package:gg_check/src/commands/can/push.dart';

// .............................................................................
/// Various checks for the source code
class Can extends Command<void> {
  /// Constructor
  Can({
    required this.log,
    DepsOfCan? deps,
  }) {
    deps ??= DepsOfCan(log: log);
    _initSubCommands(deps);
  }

  /// The log function
  final void Function(String message) log;

  /// Then name of the command
  @override
  final name = 'can';

  /// The description of the command
  @override
  final description = 'Checks if you can commit, push, publish, ....';

  // ...........................................................................
  void _initSubCommands(DepsOfCan deps) {
    addSubcommand(deps.commit);
    addSubcommand(deps.push);
    addSubcommand(deps.publish);
  }
}

// .............................................................................
/// Dependencies for the check command
class DepsOfCan {
  /// Constructor
  DepsOfCan({
    required this.log,
    Commit? commit,
    Push? push,
    Publish? publish,
  })  : commit = commit ?? Commit(log: log),
        push = push ?? Push(log: log),
        publish = publish ?? Publish(log: log);

  /// The log function
  final void Function(String msg) log;

  /// The can commit command
  final Commit commit;

  /// The can push command
  final Push push;

  /// The can publish command
  final Publish publish;
}
