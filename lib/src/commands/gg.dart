#!/usr/bin/env dart

// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_multi/gg_multi.dart' as gg_multi;

import 'gg_dna.dart';
import 'gg_multi.dart';
import 'gg_one.dart';

/// The parent command for Gg operations.
class Gg extends Command<void> {
  /// Create the root gg command and register subcommands.
  Gg({required this.ggLog}) {
    addSubcommand(GgOne(ggLog: ggLog));
    addSubcommand(GgMultiNamespace(ggLog: ggLog));
    addSubcommand(GgDna(ggLog: ggLog));

    // Register all gg_multi subcommands directly at the root: inside a gg
    // ticket workspace `gg <command>` runs gg multi by default. Standalone
    // projects are guarded in `runGg` and asked to use `gg one ...`.
    gg_multi.GgMulti(ggLog: ggLog).subcommands.values.forEach(addSubcommand);
  }

  /// The log function.
  final GgLog ggLog;

  @override
  String get name => 'gg';

  @override
  String get description => 'Work on tickets across many repos';
}
