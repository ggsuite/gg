#!/usr/bin/env dart
// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_multi/gg_multi.dart';

import 'gg_one.dart';
import 'gg_run.dart';

/// The parent command for Gg operations.
class Gg extends Command<void> {
  /// Create the root gg command and register subcommands.
  Gg({required this.ggLog}) {
    addSubcommand(GgRun(ggLog: ggLog));
    addSubcommand(GgOne(ggLog: ggLog));
    GgMulti(ggLog: ggLog).subcommands.values.forEach(addSubcommand);
  }

  /// The log function.
  final GgLog ggLog;

  @override
  String get name => 'gg';

  @override
  String get description => 'Various maintenance tasks for our repositories.';
}
