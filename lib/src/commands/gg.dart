#!/usr/bin/env dart
// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_multi/gg_multi.dart' as gg_multi;
import 'package:gg_one/gg_one.dart' as gg_one;

import '../project_detector.dart';
import 'gg_multi.dart';
import 'gg_one.dart';
import 'gg_run.dart';

/// The parent command for Gg operations.
class Gg extends Command<void> {
  /// Create the root gg command and register subcommands.
  Gg({required this.ggLog}) {
    addSubcommand(GgRun(ggLog: ggLog));
    addSubcommand(GgOne(ggLog: ggLog));
    addSubcommand(GgMultiNamespace(ggLog: ggLog));

    // Register gg_multi-only and gg_one-only top-level commands directly at
    // the root. Shared commands (can/did/do) are routed via args rewriting in
    // `runGg` to either `one` or `multi` based on the detected project mode.
    final multiSubs = gg_multi.GgMulti(ggLog: ggLog).subcommands;
    final oneSubs = gg_one.Gg(ggLog: ggLog).subcommands;
    for (final entry in multiSubs.entries) {
      if (!sharedTopLevelCommands.contains(entry.key) &&
          !oneSubs.containsKey(entry.key)) {
        addSubcommand(entry.value);
      }
    }
    for (final entry in oneSubs.entries) {
      if (!sharedTopLevelCommands.contains(entry.key) &&
          !multiSubs.containsKey(entry.key)) {
        addSubcommand(entry.value);
      }
    }
  }

  /// The log function.
  final GgLog ggLog;

  @override
  String get name => 'gg';

  @override
  String get description => 'Various maintenance tasks for our repositories.';
}
