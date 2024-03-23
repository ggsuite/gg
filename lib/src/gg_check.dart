// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_check/src/commands/can.dart';
import 'package:gg_check/src/commands/check.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';

/// The command line interface for Ggcheck
class Ggcheck extends Command<dynamic> {
  /// Constructor
  Ggcheck({
    required this.ggLog,
    GgProcessWrapper processWrapper = const GgProcessWrapper(),
  }) {
    addSubcommand(Check(ggLog: ggLog));
    addSubcommand(Can(ggLog: ggLog));
  }

  /// The log function
  final GgLog ggLog;

  // ...........................................................................
  @override
  final name = 'ggcheck';
  @override
  final description = 'Add your description here.';
}
