// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_check/gg_check.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_process/gg_process.dart';
import 'package:gg_version/gg_version.dart';

// #############################################################################
/// Base class for all ggGit commands
class Check extends Command<dynamic> {
  /// Constructor
  Check({
    required this.log,
    this.processWrapper = const GgProcessWrapper(),
  }) {
    addSubcommand(Analyze(log: log, processWrapper: processWrapper));
    addSubcommand(Format(log: log, processWrapper: processWrapper));
    addSubcommand(Coverage(log: log, processWrapper: processWrapper));
    addSubcommand(Pana(log: log, processWrapper: processWrapper));
    addSubcommand(Pushed(log: log, processWrapper: processWrapper));
    addSubcommand(Commited(log: log, processWrapper: processWrapper));
    addSubcommand(Versioned(log: log, processWrapper: processWrapper));
  }

  /// The log function
  final void Function(String message) log;

  /// Then name of the command
  @override
  final name = 'check';

  /// The description of the command
  @override
  final description = 'Various commands for checking the source code.';

  /// The process wrapper used to execute shell processes
  final GgProcessWrapper processWrapper;
}
