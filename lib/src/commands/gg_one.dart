#!/usr/bin/env dart
// @license
// Copyright (c) 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_one/gg_one.dart' as gg_one;
import 'package:gg_log/gg_log.dart';

/// Command that exposes all gg subcommands under the gg namespace.
class GgOne extends Command<void> {
  /// Create the command and register all gg subcommands.
  GgOne({required this.ggLog}) {
    gg_one.Gg(ggLog: ggLog).subcommands.values.forEach(addSubcommand);
  }

  /// The log function.
  final GgLog ggLog;

  @override
  String get name => 'one';

  @override
  String get description => 'Provides access to gg subcommands.';
}
