#!/usr/bin/env dart
// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_multi/gg_multi.dart' as gg_multi;

/// Command that exposes all gg_multi subcommands under the `multi` namespace.
class GgMultiNamespace extends Command<void> {
  /// Create the command and register all gg_multi subcommands.
  GgMultiNamespace({required this.ggLog}) {
    gg_multi.GgMulti(ggLog: ggLog).subcommands.values.forEach(addSubcommand);
  }

  /// The log function.
  final GgLog ggLog;

  @override
  String get name => 'multi';

  @override
  String get description => 'Provides access to gg_multi subcommands.';

  /// Hidden because all gg_multi subcommands are also registered at the gg
  /// root; the namespace stays available for explicit invocation.
  @override
  bool get hidden => true;
}
