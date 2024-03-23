// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg/src/commands/can/commit.dart';
import 'package:gg/src/commands/can/publish.dart';
import 'package:gg/src/commands/can/push.dart';
import 'package:gg_log/gg_log.dart';

// .............................................................................
/// Various checks for the source code
class Can extends Command<void> {
  /// Constructor
  Can({
    required this.ggLog,
    DepsOfCan? deps,
  }) {
    deps ??= DepsOfCan(ggLog: ggLog);
    _initSubCommands(deps);
  }

  /// The log function
  final GgLog ggLog;

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
    required this.ggLog,
    Commit? commit,
    Push? push,
    Publish? publish,
  })  : commit = commit ?? Commit(ggLog: ggLog),
        push = push ?? Push(ggLog: ggLog),
        publish = publish ?? Publish(ggLog: ggLog);

  /// The log function
  final GgLog ggLog;

  /// The can commit command
  final Commit commit;

  /// The can push command
  final Push push;

  /// The can publish command
  final Publish publish;
}
