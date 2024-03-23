// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_check/gg_check.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_version/gg_version.dart';
import 'package:gg_publish/gg_publish.dart';

// .............................................................................
/// Various checks for the source code
class Check extends Command<void> {
  /// Constructor
  Check({
    required this.ggLog,
    CheckCommands? commands,
  }) : commands = commands ?? CheckCommands(ggLog: ggLog) {
    _initSubCommands();
  }

  /// The log function
  final GgLog ggLog;

  /// Then name of the command
  @override
  final name = 'check';

  /// The description of the command
  @override
  final description = 'Various commands for checking the source code.';

  // ...........................................................................
  /// The check commands
  final CheckCommands commands;

  // ...........................................................................
  void _initSubCommands() {
    final c = commands;
    addSubcommand(c.analyze);
    addSubcommand(c.format);
    addSubcommand(c.coverage);
    addSubcommand(c.pana);
    addSubcommand(c.isPushed);
    addSubcommand(c.isCommitted);
    addSubcommand(c.isVersioned);
    addSubcommand(c.isPublished);
    addSubcommand(c.isUpgraded);
  }
}

// .............................................................................
/// Dependencies for the check command
class CheckCommands {
  /// Constructor
  CheckCommands({
    required this.ggLog,
    Analyze? analyze,
    Format? format,
    Coverage? coverage,
    Pana? pana,
    IsPushed? isPushed,
    IsCommitted? isCommitted,
    IsVersioned? isVersioned,
    IsPublished? isPublished,
    IsUpgraded? isUpgraded,
  })  : analyze = analyze ?? Analyze(ggLog: ggLog),
        format = format ?? Format(ggLog: ggLog),
        coverage = coverage ?? Coverage(ggLog: ggLog),
        pana = pana ?? Pana(ggLog: ggLog),
        isPushed = isPushed ?? IsPushed(ggLog: ggLog),
        isCommitted = isCommitted ?? IsCommitted(ggLog: ggLog),
        isVersioned = isVersioned ?? IsVersioned(ggLog: ggLog),
        isPublished = isPublished ?? IsPublished(ggLog: ggLog),
        isUpgraded = isUpgraded ?? IsUpgraded(ggLog: ggLog);

  /// The log function
  final GgLog ggLog;

  /// The analyze command
  final Analyze analyze;

  /// The format command
  final Format format;

  /// The coverage command
  final Coverage coverage;

  /// The pana command
  final Pana pana;

  /// The isPushed command
  final IsPushed isPushed;

  /// The isCommitted command
  final IsCommitted isCommitted;

  /// The isVersioned command
  final IsVersioned isVersioned;

  /// The isPublished command
  final IsPublished isPublished;

  /// The isUpgraded command
  final IsUpgraded isUpgraded;
}
