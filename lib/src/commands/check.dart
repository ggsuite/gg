// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_check/gg_check.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_version/gg_version.dart';
import 'package:gg_publish/gg_publish.dart';

// .............................................................................
/// Various checks for the source code
class Check extends Command<void> {
  /// Constructor
  Check({
    required this.log,
    CheckCommands? commands,
  }) : commands = commands ?? CheckCommands(log: log) {
    _initSubCommands();
  }

  /// The log function
  final void Function(String message) log;

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
    required this.log,
    Analyze? analyze,
    Format? format,
    Coverage? coverage,
    Pana? pana,
    IsPushed? isPushed,
    IsCommitted? isCommitted,
    IsVersioned? isVersioned,
    IsPublished? isPublished,
    IsUpgraded? isUpgraded,
  })  : analyze = analyze ?? Analyze(log: log),
        format = format ?? Format(log: log),
        coverage = coverage ?? Coverage(log: log),
        pana = pana ?? Pana(log: log),
        isPushed = isPushed ?? IsPushed(log: log),
        isCommitted = isCommitted ?? IsCommitted(log: log),
        isVersioned = isVersioned ?? IsVersioned(log: log),
        isPublished = isPublished ?? IsPublished(log: log),
        isUpgraded = isUpgraded ?? IsUpgraded(log: log);

  /// The log function
  final void Function(String msg) log;

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
