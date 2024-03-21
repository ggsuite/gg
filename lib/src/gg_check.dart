// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_check/src/commands/can.dart';
import 'package:gg_check/src/commands/check.dart';
import 'package:gg_process/gg_process.dart';

/// The command line interface for Ggcheck
class Ggcheck extends Command<dynamic> {
  /// Constructor
  Ggcheck({
    required this.log,
    GgProcessWrapper processWrapper = const GgProcessWrapper(),
  }) {
    addSubcommand(Check(log: log));
    addSubcommand(Can(log: log));
  }

  /// The log function
  final void Function(String message) log;

  // ...........................................................................
  @override
  final name = 'ggcheck';
  @override
  final description = 'Add your description here.';
}
