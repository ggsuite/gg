#!/usr/bin/env dart

// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_log/gg_log.dart';
import 'package:helix/helix.dart' as helix;

/// Command that exposes all helix subcommands under the `dna` namespace.
class GgDna extends Command<void> {
  /// Create the command and register all helix subcommands.
  GgDna({required this.ggLog}) {
    helix.Helix(ggLog: ggLog).subcommands.values.forEach(addSubcommand);
  }

  /// The log function.
  final GgLog ggLog;

  @override
  String get name => 'dna';

  @override
  String get description => 'Manage the DNA of a repo';
}
